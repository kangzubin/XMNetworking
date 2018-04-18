//
//  XMChainRequestTests.m
//  XMNetworkingDemoTests
//
//  Created by Zubin Kang on 27/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMTestCase.h"

@interface XMChainRequestTests : XMTestCase

@end

@implementation XMChainRequestTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testChainRequest {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The chain requests should succeed."];
    
    [XMCenter sendChainRequest:^(XMChainRequest * _Nonnull chainRequest) {
        
        [[[chainRequest onFirst:^(XMRequest * _Nonnull request) {
            request.url = @"https://httpbin.org/get";
            request.httpMethod = kXMHTTPMethodGET;
            request.parameters = @{@"method": @"get"};
        }] onNext:^(XMRequest * _Nonnull request, id  _Nullable responseObject, BOOL * _Nonnull isSent) {
            if ([responseObject[@"args"][@"method"] isEqualToString:@"get"]) {
                request.url = @"https://httpbin.org/post";
                request.httpMethod = kXMHTTPMethodPOST;
                request.parameters = @{@"method": @"post"};
            } else {
                *isSent = NO;
            }
        }] onNext:^(XMRequest * _Nonnull request, id  _Nullable responseObject, BOOL * _Nonnull isSent) {
            if ([responseObject[@"form"][@"method"] isEqualToString:@"post"]) {
                request.url = @"https://httpbin.org/put";
                request.httpMethod = kXMHTTPMethodPUT;
                request.parameters = @{@"method": @"put"};
            } else {
                *isSent = NO;
            }
        }];
        
    } onSuccess:^(NSArray<id> * _Nonnull responseObjects) {
        XCTAssertTrue(responseObjects.count == 3);
        XCTAssertTrue([responseObjects[0][@"args"][@"method"] isEqualToString:@"get"]);
        XCTAssertTrue([responseObjects[1][@"form"][@"method"] isEqualToString:@"post"]);
        XCTAssertTrue([responseObjects[2][@"form"][@"method"] isEqualToString:@"put"]);
    } onFailure:^(NSArray<id> * _Nonnull errors) {
        XCTAssertNil(errors);
    } onFinished:^(NSArray<id> * _Nullable responseObjects, NSArray<id> * _Nullable errors) {
        XCTAssertTrue(responseObjects.count == 3);
        XCTAssertTrue([responseObjects[0][@"args"][@"method"] isEqualToString:@"get"]);
        XCTAssertTrue([responseObjects[1][@"form"][@"method"] isEqualToString:@"post"]);
        XCTAssertTrue([responseObjects[2][@"form"][@"method"] isEqualToString:@"put"]);
        XCTAssertNil(errors);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testChainRequestWithFailure1 {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The chain requests should fail."];
    
    [XMCenter sendChainRequest:^(XMChainRequest * _Nonnull chainRequest) {
        
        [[[chainRequest onFirst:^(XMRequest * _Nonnull request) {
            request.url = @"https://httpbin.org/get";
            request.httpMethod = kXMHTTPMethodGET;
            request.parameters = @{@"method": @"get"};
        }] onNext:^(XMRequest * _Nonnull request, id  _Nullable responseObject, BOOL * _Nonnull sendNext) {
            if ([responseObject[@"args"][@"method"] isEqualToString:@"get"]) {
                request.url = @"https://httpbin.org/post";
                request.httpMethod = kXMHTTPMethodPOST;
                request.parameters = @{@"method": @"post"};
            } else {
                *sendNext = NO;
            }
        }] onNext:^(XMRequest * _Nonnull request, id  _Nullable responseObject, BOOL * _Nonnull sendNext) {
            // your business validate logic code here.
            *sendNext = NO;
        }];
        
    } onSuccess:^(NSArray<id> * _Nonnull responseObjects) {
        XCTAssertNil(responseObjects);
    } onFailure:^(NSArray<id> * _Nonnull errors) {
        XCTAssertTrue(errors.count == 3);
        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);  // The success response for first request will return in errors array.
        XCTAssertTrue([errors[1][@"form"][@"method"] isEqualToString:@"post"]); // The success response for second request will return in errors array.
        XCTAssertTrue([errors[2] isKindOfClass:[NSNull class]]);                // The third request will not sent, and return an [NSNull null] object.
    } onFinished:^(NSArray<id> * _Nullable responseObjects, NSArray<id> * _Nullable errors) {
        XCTAssertNil(responseObjects);
        XCTAssertTrue(errors.count == 3);
        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);
        XCTAssertTrue([errors[1][@"form"][@"method"] isEqualToString:@"post"]);
        XCTAssertTrue([errors[2] isKindOfClass:[NSNull class]]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testChainRequestWithFailure2 {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The chain requests should fail."];
    
    [XMCenter sendChainRequest:^(XMChainRequest * _Nonnull chainRequest) {
        
        [[chainRequest onFirst:^(XMRequest * _Nonnull request) {
            request.url = @"https://httpbin.org/get";
            request.httpMethod = kXMHTTPMethodGET;
            request.parameters = @{@"method": @"get"};
        }] onNext:^(XMRequest * _Nonnull request, id  _Nullable responseObject, BOOL * _Nonnull sendNext) {
            if ([responseObject[@"args"][@"method"] isEqualToString:@"get"]) {
                request.url = @"https://kangzubin.cn/test/timeout.php"; // This interface will return in 30 seconds later.
                request.httpMethod = kXMHTTPMethodGET;
                request.timeoutInterval = 5.0;
            } else {
                *sendNext = NO;
            }
        }];
        
    } onSuccess:^(NSArray<id> * _Nonnull responseObjects) {
        XCTAssertNil(responseObjects);
    } onFailure:^(NSArray<id> * _Nonnull errors) {
        XCTAssertTrue(errors.count == 2);
        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);  // The success response for first request will return in errors array.
        XCTAssertTrue(((NSError *)errors[1]).code == NSURLErrorTimedOut);       // The Error info for second request.
    } onFinished:^(NSArray<id> * _Nullable responseObjects, NSArray<id> * _Nullable errors) {
        XCTAssertNil(responseObjects);
        XCTAssertTrue(errors.count == 2);
        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);
        XCTAssertTrue(((NSError *)errors[1]).code == NSURLErrorTimedOut);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testCancelChainRequest {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"The chain requests should succeed."];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"The Cancel block should be called."];
    
    NSString *identifier = [XMCenter sendChainRequest:^(XMChainRequest * _Nonnull chainRequest) {
        
        [[chainRequest onFirst:^(XMRequest * _Nonnull request) {
            request.url = @"https://httpbin.org/get";
            request.httpMethod = kXMHTTPMethodGET;
            request.parameters = @{@"method": @"get"};
        }] onNext:^(XMRequest * _Nonnull request, id  _Nullable responseObject, BOOL * _Nonnull sendNext) {
            if ([responseObject[@"args"][@"method"] isEqualToString:@"get"]) {
                request.url = @"https://kangzubin.cn/test/timeout.php"; // This interface will return in 30 seconds later.
                request.httpMethod = kXMHTTPMethodGET;
            } else {
                *sendNext = NO;
            }
        }];
        
    } onSuccess:^(NSArray<id> * _Nonnull responseObjects) {
        XCTAssertNil(responseObjects);
    } onFailure:^(NSArray<id> * _Nonnull errors) {
        XCTAssertTrue(errors.count == 2);
        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);  // The success response for first request will return in errors array.
        XCTAssertTrue(((NSError *)errors[1]).code == NSURLErrorCancelled);      // The Error info for second request.
    } onFinished:^(NSArray<id> * _Nullable responseObjects, NSArray<id> * _Nullable errors) {
        XCTAssertNil(responseObjects);
        XCTAssertTrue(errors.count == 2);
        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);
        XCTAssertTrue(((NSError *)errors[1]).code == NSURLErrorCancelled);
        [expectation1 fulfill];
    }];
    
    sleep(2);
    
    [XMCenter cancelRequest:identifier onCancel:^(id _Nullable request) {
        XMChainRequest *chainRequest = request;
        XCTAssertNotNil(chainRequest);
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
    
}

@end
