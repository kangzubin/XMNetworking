//
//  XMTestCase.h
//  XMNetworkingDemoTests
//
//  Created by Zubin Kang on 26/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XMNetworking.h"

@interface XMTestCase : XCTestCase

@property (nonatomic, assign) NSTimeInterval networkTimeout;

- (void)waitForExpectationsWithCommonTimeout;
- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler;

@end
