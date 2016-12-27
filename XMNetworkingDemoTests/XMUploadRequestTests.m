//
//  XMUploadRequestTests.m
//  XMNetworkingDemoTests
//
//  Created by Zubin Kang on 27/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMTestCase.h"

@interface XMUploadRequestTests : XMTestCase

@end

@implementation XMUploadRequestTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testUpload {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Upload request should succeed."];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Upload progress Should equal 1.0."];
    
    // `NSData` form data.
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"testImage" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    NSData *fileData = UIImageJPEGRepresentation(image, 1.0);
    // `NSURL` form data.
    //NSString *path = [NSHomeDirectory() stringByAppendingString:@"/Documents/testImage.jpg"];
    //NSURL *fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
        
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.server = @"https://httpbin.org/";
        request.api = @"post";
        request.requestType = kXMRequestUpload;
        [request addFormDataWithName:@"image" fileName:@"tempImage.jpg" mimeType:@"image/jpeg" fileData:fileData];
        //[request addFormDataWithName:@"file" fileURL:fileURL];
    } onProgress:^(NSProgress * _Nonnull progress) {
        // the progress block is running on the session queue.
        if (progress.fractionCompleted == 1.0) {
            [expectation2 fulfill];
        }
    } onSuccess:^(id  _Nullable responseObject) {
        XCTAssertNotNil(responseObject);
        XCTAssertTrue(responseObject[@"files"][@"image"] != nil);
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
