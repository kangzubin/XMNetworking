//
//  XMCenterTests.m
//  XMNetworkingDemoTests
//
//  Created by Zubin Kang on 27/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMTestCase.h"

@interface XMCenterTests : XMTestCase

@property (nonatomic, strong) XMCenter *testCenter1;
@property (nonatomic, strong) XMCenter *testCenter2;

@property (nonatomic, strong) XMCenter *securityCenter;

@end

@implementation XMCenterTests

- (void)setUp {
    [super setUp];
    self.testCenter1 = [XMCenter center];
    self.testCenter2 = [XMCenter center];
    self.securityCenter = [XMCenter center];
}

- (void)tearDown {
    [super tearDown];
    self.testCenter1 = nil;
    self.testCenter2 = nil;
    self.securityCenter = nil;
}

- (void)testCallbackQueue {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"The callback blocks should be called in main thread."];

    [self.testCenter1 setupConfig:^(XMConfig * _Nonnull config) {
        config.callbackQueue = dispatch_get_main_queue();
        config.consoleLog = YES;
    }];
    
    [self.testCenter1 sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/get";
        request.httpMethod = kXMHTTPMethodGET;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue([NSThread isMainThread]);
        [expectation1 fulfill];
    }];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"The callback blocks should be called in a private thread."];
    [self.testCenter2 sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/get";
        request.httpMethod = kXMHTTPMethodGET;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue(![NSThread isMainThread]);
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testSSLPinning {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The request should succeed with ssl pinning certificate mode."];
    
    [self.securityCenter setupConfig:^(XMConfig * _Nonnull config) {
        config.engine = [XMEngine engine];
        config.consoleLog = YES;
    }];
    
    // Add SSL Pinning Certificate
    NSString *certPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"httpbin.org" ofType:@"cer"];
    NSData *certData = [NSData dataWithContentsOfFile:certPath];
    [self.securityCenter.engine addSSLPinningCert:certData];
    [self.securityCenter.engine addSSLPinningURL:@"https://httpbin.org/"];
    
    [self.securityCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/get";
        request.httpMethod = kXMHTTPMethodGET;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(responseObject);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testNetworkReachability {
    XCTAssertTrue([XMCenter isNetworkReachable]);
    XCTAssertTrue([XMEngine sharedEngine].reachabilityStatus == 2);
}

@end
