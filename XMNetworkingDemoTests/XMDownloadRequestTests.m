//
//  XMDownloadRequestTests.m
//  XMNetworkingDemoTests
//
//  Created by Zubin Kang on 27/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMTestCase.h"

@interface XMDownloadRequestTests : XMTestCase

@end

@implementation XMDownloadRequestTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDownload {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download request should succeed."];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download progress Should equal 1.0."];

    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/image/png";
        request.requestType = kXMRequestDownload;
        request.downloadSavePath = [NSHomeDirectory() stringByAppendingString:@"/Documents/temp.png"];
    } onProgress:^(NSProgress * _Nonnull progress) {
        // the progress block is running on the session queue.
        if (progress.fractionCompleted == 1.0) {
            [expectation2 fulfill];
        }
    } onSuccess:^(id  _Nullable responseObject) {
        XCTAssertNotNil(responseObject);
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:((NSURL *)responseObject).path]);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertNotNil(responseObject);
        XCTAssertNil(error);
        [expectation1 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

@end
