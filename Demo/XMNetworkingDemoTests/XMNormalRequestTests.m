//
//  XMNormalRequestTests.m
//  XMNetworkingDemoTests
//
//  Created by Zubin Kang on 26/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMTestCase.h"

@interface XMNormalRequestTests : XMTestCase

@end

@implementation XMNormalRequestTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testGET {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request with GET method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.api = @"get";
        request.httpMethod = kXMHTTPMethodGET;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertNotNil(responseObject);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testGETWithParameters {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request with GET method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/get";
        request.parameters = @{@"key": @"value"};
        request.httpMethod = kXMHTTPMethodGET;
        request.useGeneralParameters = NO;
        request.useGeneralHeaders = NO;
    } onSuccess:^(id  _Nullable responseObject) {
        XCTAssertTrue([responseObject[@"args"][@"key"] isEqualToString:@"value"]);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue([responseObject[@"args"][@"key"] isEqualToString:@"value"]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPOSTWithForm {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request with POST method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.server = @"https://httpbin.org/";
        request.api = @"post";
        request.parameters = @{@"key": @"value"};
        request.requestType = kXMRequestNormal; // optional, default to `kXMRequestNormal`
        request.httpMethod = kXMHTTPMethodPOST; // optional, default to `kXMHTTPMethodPOST`
        request.requestSerializerType = kXMRequestSerializerRAW;    // optional, defautl to `kXMRequestSerializerRAW`
        request.responseSerializerType = kXMResponseSerializerJSON; // optional, defautl to `kXMResponseSerializerJSON`
    } onSuccess:^(id  _Nullable responseObject) {
        XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
        XCTAssertTrue([responseObject[@"form"][@"global_param"] isEqualToString:@"global param value"]);
        XCTAssertTrue([responseObject[@"headers"][@"Global-Header"] isEqualToString:@"global header value"]);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
        XCTAssertTrue([responseObject[@"form"][@"global_param"] isEqualToString:@"global param value"]);
        XCTAssertTrue([responseObject[@"headers"][@"Global-Header"] isEqualToString:@"global header value"]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPOSTWithJSON {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request with POST method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.server = @"https://httpbin.org/";
        request.api = @"post";
        request.parameters = @{@"key": @"value"};
        request.requestSerializerType = kXMRequestSerializerJSON;
    } onSuccess:^(id  _Nullable responseObject) {
        XCTAssertTrue([responseObject[@"json"][@"key"] isEqualToString:@"value"]);
        XCTAssertTrue([responseObject[@"json"][@"global_param"] isEqualToString:@"global param value"]);
        XCTAssertTrue([responseObject[@"headers"][@"Global-Header"] isEqualToString:@"global header value"]);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue([responseObject[@"json"][@"key"] isEqualToString:@"value"]);
        XCTAssertTrue([responseObject[@"json"][@"global_param"] isEqualToString:@"global param value"]);
        XCTAssertTrue([responseObject[@"headers"][@"Global-Header"] isEqualToString:@"global header value"]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPOSTWithPlist {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request with POST method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.server = @"https://httpbin.org/";
        request.api = @"post";
        request.useGeneralHeaders = NO;
        request.useGeneralParameters = NO;
        request.parameters = @{@"key1": @"value1", @"key2": @"value2"};
        request.requestSerializerType = kXMRequestSerializerPlist;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        NSString *data = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n\t<key>key1</key>\n\t<string>value1</string>\n\t<key>key2</key>\n\t<string>value2</string>\n</dict>\n</plist>\n";
        XCTAssertTrue([responseObject[@"data"] isEqualToString:data]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testResponseWithRAW {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Response with RAW method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.server = @"https://httpbin.org/";
        request.api = @"html";
        request.httpMethod = kXMHTTPMethodGET;
        request.responseSerializerType = kXMResponseSerializerRAW;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertNotNil(responseObject);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testResponseWithJSON {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Response with JSON method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.server = @"https://httpbin.org/";
        request.api = @"post";
        request.useGeneralHeaders = NO;
        request.useGeneralParameters = NO;
        request.parameters = @{@"key1": @"value1", @"key2": @"value2"};
        request.responseSerializerType = kXMResponseSerializerJSON; // default value
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue([responseObject[@"form"][@"key1"] isEqualToString:@"value1"]);
        XCTAssertTrue([responseObject[@"form"][@"key2"] isEqualToString:@"value2"]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testResponseWithXML {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Response with XML method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.server = @"https://httpbin.org/";
        request.api = @"xml";
        request.httpMethod = kXMHTTPMethodGET;
        request.responseSerializerType = kXMResponseSerializerXML;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue([responseObject isKindOfClass:[NSXMLParser class]]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testHEAD {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request with HEAD method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/get";
        request.httpMethod = kXMHTTPMethodHEAD;
        request.useGeneralParameters = NO;
        request.useGeneralHeaders = NO;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPUT {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request with PUT method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/put";
        request.parameters = @{@"key": @"value"};
        request.httpMethod = kXMHTTPMethodPUT;
        request.useGeneralParameters = NO;
        request.useGeneralHeaders = NO;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testDELETE {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request with DELETE method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/delete";
        request.parameters = @{@"key": @"value"};
        request.httpMethod = kXMHTTPMethodDELETE;
        request.useGeneralParameters = NO;
        request.useGeneralHeaders = NO;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue([responseObject[@"args"][@"key"] isEqualToString:@"value"]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testPATCH {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request with PATCH method should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/patch";
        request.parameters = @{@"key": @"value"};
        request.httpMethod = kXMHTTPMethodPATCH;
        request.useGeneralParameters = NO;
        request.useGeneralHeaders = NO;
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue([responseObject[@"form"][@"key"] isEqualToString:@"value"]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUserAgnet {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request with custom user agent should succeed."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/user-agent";
        request.headers = @{@"User-Agent": @"XMNetworking Custom User Agent"};
        request.httpMethod = kXMHTTPMethodGET;
        request.useGeneralParameters = NO;
        request.useGeneralHeaders = NO;
    } onSuccess:^(id  _Nullable responseObject) {
        XCTAssertTrue([responseObject[@"user-agent"] isEqualToString:@"XMNetworking Custom User Agent"]);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNil(error);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertTrue([responseObject[@"user-agent"] isEqualToString:@"XMNetworking Custom User Agent"]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testRequestWithFailure {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should fail."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://httpbin.org/status/404";
        request.httpMethod = kXMHTTPMethodGET;
        request.useGeneralParameters = NO;
        request.useGeneralHeaders = NO;
    } onSuccess:^(id  _Nullable responseObject) {
        XCTAssertNil(responseObject);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertNil(responseObject);
        XCTAssertNotNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testTimeOut {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Request should fail due to time out."];
    [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://kangzubin.cn/test/timeout.php"; // This interface will return in 30 seconds later.
        request.httpMethod = kXMHTTPMethodGET;
        request.timeoutInterval = 5.0;
        request.useGeneralParameters = NO;
        request.useGeneralHeaders = NO;
    } onSuccess:^(id  _Nullable responseObject) {
        XCTAssertNil(responseObject);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertTrue(error.code == NSURLErrorTimedOut);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertNil(responseObject);
        XCTAssertNotNil(error);
        XCTAssertTrue(error.code == NSURLErrorTimedOut);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testCancelRunningRequest {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Request should fail due to manually cancelled."];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Cancel block should be called."];
    
    NSString *identifier = [XMCenter sendRequest:^(XMRequest * _Nonnull request) {
        request.url = @"https://kangzubin.cn/test/timeout.php"; // This interface will return in 30 seconds later.
        request.httpMethod = kXMHTTPMethodGET;
        request.useGeneralParameters = NO;
        request.useGeneralHeaders = NO;
    } onSuccess:^(id  _Nullable responseObject) {
        XCTAssertNil(responseObject);
    } onFailure:^(NSError * _Nullable error) {
        XCTAssertNotNil(error);
        XCTAssertTrue(error.code == NSURLErrorCancelled);
    } onFinished:^(id  _Nullable responseObject, NSError * _Nullable error) {
        XCTAssertNil(responseObject);
        XCTAssertNotNil(error);
        XCTAssertTrue(error.code == NSURLErrorCancelled);
        [expectation1 fulfill];
    }];
    
    sleep(2);
    
    [XMCenter cancelRequest:identifier onCancel:^(XMRequest * _Nullable request) {
        XCTAssertNotNil(request);
        XCTAssertTrue([request.url isEqualToString:@"https://kangzubin.cn/test/timeout.php"]);
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

@end
