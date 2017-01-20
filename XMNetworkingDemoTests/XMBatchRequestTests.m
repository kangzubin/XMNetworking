//
//  XMBatchRequestTests.m
//  XMNetworkingDemoTests
//
//  Created by Zubin Kang on 27/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMTestCase.h"

@interface XMBatchRequestTests : XMTestCase

@end

@implementation XMBatchRequestTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testBatchRequest {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The batch requests should succeed."];
    
    [XMCenter sendBatchRequest:^(XMBatchRequest * _Nonnull batchRequest) {
        XMRequest *request1 = [XMRequest request];
        request1.url = @"https://httpbin.org/get";
        request1.httpMethod = kXMHTTPMethodGET;
        request1.parameters = @{@"method": @"get"};
        
        XMRequest *request2 = [XMRequest request];
        request2.url = @"https://httpbin.org/post";
        request2.httpMethod = kXMHTTPMethodPOST;
        request2.parameters = @{@"method": @"post"};
        
        XMRequest *request3 = [XMRequest request];
        request3.url = @"https://httpbin.org/put";
        request3.httpMethod = kXMHTTPMethodPUT;
        request3.parameters = @{@"method": @"put"};
        
        [batchRequest.requestArray addObject:request1];
        [batchRequest.requestArray addObject:request2];
        [batchRequest.requestArray addObject:request3];
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

- (void)testBatchRequestWithFailure {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The batch requests should fail."];
    
    [XMCenter sendBatchRequest:^(XMBatchRequest * _Nonnull batchRequest) {
        XMRequest *request1 = [XMRequest request];
        request1.url = @"https://httpbin.org/get";
        request1.httpMethod = kXMHTTPMethodGET;
        request1.parameters = @{@"method": @"get"};
        
        XMRequest *request2 = [XMRequest request];
        request2.url = @"https://kangzubin.cn/test/timeout.php"; // This interface will return in 30 seconds later.
        request2.httpMethod = kXMHTTPMethodGET;
        request2.timeoutInterval = 5.0;
        
        XMRequest *request3 = [XMRequest request];
        request3.url = @"https://httpbin.org/post";
        request3.httpMethod = kXMHTTPMethodPOST;
        request3.parameters = @{@"method": @"post"};
        
        [batchRequest.requestArray addObject:request1];
        [batchRequest.requestArray addObject:request2];
        [batchRequest.requestArray addObject:request3];
    } onSuccess:^(NSArray<id> * _Nonnull responseObjects) {
        XCTAssertNil(responseObjects);
    } onFailure:^(NSArray<id> * _Nonnull errors) {
        XCTAssertTrue(errors.count == 3);
        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);  // The success response for first request will return in errors array.
        XCTAssertTrue(((NSError *)errors[1]).code == NSURLErrorTimedOut);       // The Error info for second request.
        XCTAssertTrue([errors[2][@"form"][@"method"] isEqualToString:@"post"]); // The success response for third request will return in errors array.
    } onFinished:^(NSArray<id> * _Nullable responseObjects, NSArray<id> * _Nullable errors) {
        XCTAssertNil(responseObjects);
        XCTAssertTrue(errors.count == 3);
        XCTAssertTrue([errors[0][@"args"][@"method"] isEqualToString:@"get"]);
        XCTAssertTrue(((NSError *)errors[1]).code == NSURLErrorTimedOut);
        XCTAssertTrue([errors[2][@"form"][@"method"] isEqualToString:@"post"]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testCancelBatchRequest {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"The batch requests should succeed."];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"The Cancel block should be called."];
    
    NSString *identifier = [XMCenter sendBatchRequest:^(XMBatchRequest * _Nonnull batchRequest) {
        XMRequest *request1 = [XMRequest request];
        request1.url = @"https://httpbin.org/get";
        request1.httpMethod = kXMHTTPMethodGET;
        request1.parameters = @{@"method": @"get"};
        
        XMRequest *request2 = [XMRequest request];
        request2.url = @"https://kangzubin.cn/test/timeout.php"; // This interface will return in 30 seconds later.
        request2.httpMethod = kXMHTTPMethodGET;
        
        [batchRequest.requestArray addObject:request1];
        [batchRequest.requestArray addObject:request2];
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
        XMBatchRequest *batchRequest = request;
        XCTAssertNotNil(batchRequest);
        XCTAssertTrue(batchRequest.requestArray.count == 2);
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

@end
