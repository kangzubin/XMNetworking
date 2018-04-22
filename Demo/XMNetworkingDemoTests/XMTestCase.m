//
//  XMTestCase.m
//  XMNetworkingDemoTests
//
//  Created by Zubin Kang on 26/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMTestCase.h"

@implementation XMTestCase

- (void)setUp {
    [super setUp];
    self.networkTimeout = 20.0;
    [XMCenter setupConfig:^(XMConfig * _Nonnull config) {
        config.generalServer = @"https://httpbin.org/";
        config.generalParameters = @{@"global_param": @"global param value"};
        config.generalHeaders = @{@"global_header": @"global header value"};
        config.consoleLog = YES;
    }];
    
    [XMCenter setRequestProcessBlock:^(XMRequest * _Nonnull request) {
        
    }];
    [XMCenter setResponseProcessBlock:^id(XMRequest * _Nonnull request, id  _Nullable responseObject, NSError *__autoreleasing  _Nullable * _Nullable error) {
        return nil;
    }];
    [XMCenter setErrorProcessBlock:^(XMRequest * _Nonnull request, NSError *__autoreleasing  _Nullable * _Nullable error) {
        
    }];
}

- (void)tearDown {
    [super tearDown];
}

- (void)waitForExpectationsWithCommonTimeout {
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler {
    [self waitForExpectationsWithTimeout:self.networkTimeout handler:handler];
}

@end
