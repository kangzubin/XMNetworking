//
//  XMEngine.h
//  XMNetworking
//
//  Created by Zubin Kang on 12/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class XMRequest;

/**
 The completion handler block for a network request.
 
 @param responseObject The response object return by the response serializer.
 @param error The error describing the network or parsing error that occurred.
 */
typedef void (^XMCompletionHandler) (id _Nullable responseObject, NSError * _Nullable error);

/**
 `XMEngine` is a global engine to lauch the all network requests, which package the API of `AFNetworking`.
 */
@interface XMEngine : NSObject

///---------------------
/// @name Initialization
///---------------------

/**
 Creates and returns a new `XMEngine` object.
 */
+ (instancetype)engine;

/**
 Returns the default shared `XMEngine` singleton object.
 */
+ (instancetype)sharedEngine;

///------------------------
/// @name Request Operation
///------------------------

/**
 Runs a real network reqeust with a `XMRequest` object and completion handler block.
 
 @param request The `XMRequest` object to be launched.
 @param completionHandler The completion handler block for network response callback.
 */
- (void)sendRequest:(XMRequest *)request completionHandler:(nullable XMCompletionHandler)completionHandler;

/**
 Method to cancel a runnig request by identifier
 
 @param identifier The unique identifier of a running request.
 @return return The canceled request object (if exist) matching to identifier.
 */
- (nullable XMRequest *)cancelRequestByIdentifier:(NSString *)identifier;

/**
 Method to get a runnig request object matching to identifier.
 
 @param identifier The unique identifier of a running request.
 @return return The runing requset object (if exist) matching to identifier.
 */
- (nullable XMRequest *)getRequestByIdentifier:(NSString *)identifier;

///--------------------------
/// @name Network Reachablity
///--------------------------

/**
 Method to get the current network reachablity status, see `AFNetworkReachabilityManager.h` for details.

 @return Network reachablity status code
 */
- (NSInteger)reachabilityStatus;

///----------------------------
/// @name SSL Pinning for HTTPS
///----------------------------

/**
 Add host url of a server whose trust should be evaluated against the pinned SSL certificates.

 @param url The host url of a server.
 */
- (void)addSSLPinningURL:(NSString *)url;

/**
 Add certificate used to evaluate server trust according to the SSL pinning URL.

 @param cert The local pinnned certificate data.
 */
- (void)addSSLPinningCert:(NSData *)cert;

///---------------------------------------
/// @name Two-way Authentication for HTTPS
///---------------------------------------

/**
 Add client p12 certificate used for HTTPS Two-way Authentication.

 @param p12 The PKCS#12 certificate file data.
 @param password The special key password for PKCS#12 data.
 */
- (void)addTwowayAuthenticationPKCS12:(NSData *)p12 keyPassword:(NSString *)password;

@end

NS_ASSUME_NONNULL_END
