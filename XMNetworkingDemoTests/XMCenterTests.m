//
//  XMCenterTests.m
//  XMNetworkingDemo
//
//  Created by Zubin Kang on 27/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMTestCase.h"

@interface XMCenterTests : XMTestCase

@property (nonatomic, strong) XMCenter *testCenter1;
@property (nonatomic, strong) XMCenter *testCenter2;

@end

@implementation XMCenterTests

- (void)setUp {
    [super setUp];
    self.testCenter1 = [XMCenter center];
    self.testCenter2 = [XMCenter center];
}

- (void)tearDown {
    [super tearDown];
    self.testCenter1 = nil;
    self.testCenter2 = nil;
}

- (void)testCallbackQueue {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"The callback blocks should be called in main thread."];
    self.testCenter1.callbackQueue = dispatch_get_main_queue();
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
        NSLog(@"%@", error);
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

//- (void)testSSLPinning {
//    NSString *certPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"httpbin" ofType:@"cer"];
//    NSData *certData = [NSData dataWithContentsOfFile:certPath];
//    [XMEngine sharedEngine].sessionManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
//    [[XMEngine sharedEngine].sessionManager.securityPolicy setPinnedCertificates:[NSSet setWithObjects:certData, nil]];
//    
//    XCTestExpectation *expectation = [self expectationWithDescription:@"The request should succeed with ssl pinning certificate mode."];
//    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
//        request.url = @"https://httpbin.org/get";
//        request.httpMethod = kXMHTTPMethodGET;
//    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
//        XCTAssertNil(error);
//        XCTAssertNotNil(responseObject);
//        [expectation fulfill];
//    }];
//    [self waitForExpectationsWithCommonTimeout];
//}

- (void)testNetworkReachability {
    XCTAssertTrue([XMCenter isNetworkReachable]);
    XCTAssertTrue([XMEngine sharedEngine].networkReachability == 2);
}

@end
