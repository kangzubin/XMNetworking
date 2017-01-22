//
//  XMCenter.h
//  XMNetworking
//
//  Created by Zubin Kang on 12/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMConst.h"

NS_ASSUME_NONNULL_BEGIN

@class XMConfig, XMEngine;

/**
 `XMCenter` is a global central place to send and manage all network requests.
 `+center` method is used to creates a new `XMCenter` object,
 `+defaultCenter` method will return a default shared `XMCenter` singleton object.
 
 The class methods for `XMCenter` are invoked by `[XMCenter defaultCenter]`, which are recommend to use `Class Method` instead of manager a `XMCenter` yourself.
 
 Usage:
 
 (1) Config XMCenter
 
 [XMCenter setupConfig:^(XMConfig *config) {
     config.server = @"general server address";
     config.headers = @{@"general header": @"general header value"};
     config.parameters = @{@"general parameter": @"general parameter value"};
     config.callbackQueue = dispatch_get_main_queue(); // set callback dispatch queue
 }];
 
 [XMCenter setRequestProcessBlock:^(XMRequest *request) {
     // Do the custom request pre processing logic by yourself.
 }];
 
 [XMCenter setResponseProcessBlock:^(XMRequest *request, id responseObject, NSError *__autoreleasing *error) {
     // Do the custom response data processing logic by yourself.
     // You can assign the passed in `error` argument when error occurred, and the failure block will be called instead of success block.
 }];
 
 (2) Send a Request
 
 [XMCenter sendRequest:^(XMRequest *request) {
     request.server = @"server address"; // optional, if `nil`, the genneal server is used.
     request.api = @"api path";
     request.parameters = @{@"param1": @"value1", @"param2": @"value2"}; // and the general parameters will add to reqeust parameters.
 } onSuccess:^(id responseObject) {
     // success code here...
 } onFailure:^(NSError *error) {
     // failure code here...
 }];
 
 */
@interface XMCenter : NSObject

///---------------------
/// @name Initialization
///---------------------

/**
 Creates and returns a new `XMCenter` object.
 */
+ (instancetype)center;

/**
 Returns the default shared `XMCenter` singleton object.
 */
+ (instancetype)defaultCenter;

///-----------------------
/// @name General Property
///-----------------------

// NOTE: The following properties could only be assigned by `XMConfig` through invoking `-setupConfig:` method.

/**
 The general server address for XMCenter, if XMRequest.server is `nil` and the XMRequest.useGeneralServer is `YES`, this property will be assigned to XMRequest.server.
 */
@property (nonatomic, copy, nullable) NSString *generalServer;

/**
 The general parameters for XMCenter, if XMRequest.useGeneralParameters is `YES` and this property is not empty, it will be appended to XMRequest.parameters.
 */
@property (nonatomic, strong, nullable, readonly) NSMutableDictionary<NSString *, id> *generalParameters;

/**
 The general headers for XMCenter, if XMRequest.useGeneralHeaders is `YES` and this property is not empty, it will be appended to XMRequest.headers.
 */
@property (nonatomic, strong, nullable, readonly) NSMutableDictionary<NSString *, NSString *> *generalHeaders;

/**
 The general user info for XMCenter, if XMRequest.userInfo is `nil` and this property is not `nil`, it will be assigned to XMRequest.userInfo.
 */
@property (nonatomic, strong, nullable) NSDictionary *generalUserInfo;

/**
 The dispatch queue for callback blocks. If `NULL` (default), a private concurrent queue is used.
 */
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

/**
 The global requests engine for current XMCenter object, `[XMEngine sharedEngine]` by default.
 */
@property (nonatomic, strong) XMEngine *engine;

/**
 Whether or not to print the request and response info in console, `NO` by default.
 */
@property (nonatomic, assign) BOOL consoleLog;

///--------------------------------------------
/// @name Instance Method to Configure XMCenter
///--------------------------------------------

#pragma mark - Instance Method

/**
 Method to config the XMCenter properties by a `XMConfig` object.

 @param block The config block to assign the values for `XMConfig` object.
 */
- (void)setupConfig:(void(^)(XMConfig *config))block;

/**
 Method to set custom request pre processing block for XMCenter.
 
 @param block The custom processing block (`XMCenterRequestProcessBlock`).
 */
- (void)setRequestProcessBlock:(XMCenterRequestProcessBlock)block;

/**
 Method to set custom response data processing block for XMCenter.

 @param block The custom processing block (`XMCenterResponseProcessBlock`).
 */
- (void)setResponseProcessBlock:(XMCenterResponseProcessBlock)block;

/**
 Sets the value for the general HTTP headers of XMCenter, If value is `nil`, it will remove the existing value for that header field.
 
 @param value The value to set for the specified header, or `nil`.
 @param field The HTTP header to set a value for.
 */
- (void)setGeneralHeaderValue:(nullable NSString *)value forField:(NSString *)field;

/**
 Sets the value for the general parameters of XMCenter, If value is `nil`, it will remove the existing value for that parameter key.
 
 @param value The value to set for the specified parameter, or `nil`.
 @param key The parameter key to set a value for.
 */
- (void)setGeneralParameterValue:(nullable id)value forKey:(NSString *)key;

///---------------------------------------
/// @name Instance Method to Send Requests
///---------------------------------------

#pragma mark -

/**
 Creates and runs a Normal `XMRequest`.

 @param configBlock The config block to setup context info for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock;

/**
 Creates and runs a Normal `XMRequest` with success block.
 
 NOTE: The success block will be called on `callbackQueue` of XMCenter.

 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param successBlock Success callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                         onSuccess:(nullable XMSuccessBlock)successBlock;

/**
 Creates and runs a Normal `XMRequest` with failure block.
 
 NOTE: The failure block will be called on `callbackQueue` of XMCenter.

 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param failureBlock Failure callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                         onFailure:(nullable XMFailureBlock)failureBlock;

/**
 Creates and runs a Normal `XMRequest` with finished block.

 NOTE: The finished block will be called on `callbackQueue` of XMCenter.
 
 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param finishedBlock Finished callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                        onFinished:(nullable XMFinishedBlock)finishedBlock;

/**
 Creates and runs a Normal `XMRequest` with success/failure blocks.

 NOTE: The success/failure blocks will be called on `callbackQueue` of XMCenter.
 
 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param successBlock Success callback block for the new created XMRequest object.
 @param failureBlock Failure callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                         onSuccess:(nullable XMSuccessBlock)successBlock
                         onFailure:(nullable XMFailureBlock)failureBlock;

/**
 Creates and runs a Normal `XMRequest` with success/failure/finished blocks.

 NOTE: The success/failure/finished blocks will be called on `callbackQueue` of XMCenter.
 
 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param successBlock Success callback block for the new created XMRequest object.
 @param failureBlock Failure callback block for the new created XMRequest object.
 @param finishedBlock Finished callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                         onSuccess:(nullable XMSuccessBlock)successBlock
                         onFailure:(nullable XMFailureBlock)failureBlock
                        onFinished:(nullable XMFinishedBlock)finishedBlock;

/**
 Creates and runs an Upload/Download `XMRequest` with progress/success/failure blocks.

 NOTE: The success/failure blocks will be called on `callbackQueue` of XMCenter.
 BUT !!! the progress block is called on the session queue, not the `callbackQueue` of XMCenter.
 
 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param progressBlock Progress callback block for the new created XMRequest object.
 @param successBlock Success callback block for the new created XMRequest object.
 @param failureBlock Failure callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                        onProgress:(nullable XMProgressBlock)progressBlock
                         onSuccess:(nullable XMSuccessBlock)successBlock
                         onFailure:(nullable XMFailureBlock)failureBlock;

/**
 Creates and runs an Upload/Download `XMRequest` with progress/success/failure/finished blocks.

 NOTE: The success/failure/finished blocks will be called on `callbackQueue` of XMCenter.
 BUT !!! the progress block is called on the session queue, not the `callbackQueue` of XMCenter.
 
 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param progressBlock Progress callback block for the new created XMRequest object.
 @param successBlock Success callback block for the new created XMRequest object.
 @param failureBlock Failure callback block for the new created XMRequest object.
 @param finishedBlock Finished callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`nil` for fail.
 */
- (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                        onProgress:(nullable XMProgressBlock)progressBlock
                         onSuccess:(nullable XMSuccessBlock)successBlock
                         onFailure:(nullable XMFailureBlock)failureBlock
                        onFinished:(nullable XMFinishedBlock)finishedBlock;

/**
 Creates and runs batch requests

 @param configBlock The config block to setup batch requests context info for the new created XMBatchRequest object.
 @param successBlock Success callback block called when all batch requests finished successfully.
 @param failureBlock Failure callback block called once a request error occured.
 @param finishedBlock Finished callback block for the new created XMBatchRequest object.
 @return Unique identifier for the new running XMBatchRequest object,`nil` for fail.
 */
- (nullable NSString *)sendBatchRequest:(XMBatchRequestConfigBlock)configBlock
                                    onSuccess:(nullable XMBCSuccessBlock)successBlock
                                    onFailure:(nullable XMBCFailureBlock)failureBlock
                                   onFinished:(nullable XMBCFinishedBlock)finishedBlock;

/**
 Creates and runs chain requests

 @param configBlock The config block to setup chain requests context info for the new created XMBatchRequest object.
 @param successBlock Success callback block called when all chain requests finished successfully.
 @param failureBlock Failure callback block called once a request error occured.
 @param finishedBlock Finished callback block for the new created XMChainRequest object.
 @return Unique identifier for the new running XMChainRequest object,`nil` for fail.
 */
- (nullable NSString *)sendChainRequest:(XMChainRequestConfigBlock)configBlock
                                    onSuccess:(nullable XMBCSuccessBlock)successBlock
                                    onFailure:(nullable XMBCFailureBlock)failureBlock
                                   onFinished:(nullable XMBCFinishedBlock)finishedBlock;

///------------------------------------------
/// @name Instance Method to Operate Requests
///------------------------------------------

#pragma mark -

/**
 Method to cancel a runnig request by identifier.
 
 @param identifier The unique identifier of a running request.
 */
- (void)cancelRequest:(NSString *)identifier;

/**
 Method to cancel a runnig request by identifier with a cancel block.
 
 NOTE: The cancel block is called on current thread who invoked the method, not the `callbackQueue` of XMCenter.
 
 @param identifier The unique identifier of a running request.
 @param cancelBlock The callback block to be executed after the running request is canceled. The canceled request object (if exist) will be passed in argument to the cancel block.
 */
- (void)cancelRequest:(NSString *)identifier
             onCancel:(nullable XMCancelBlock)cancelBlock;

/**
 Method to get a runnig request object matching to identifier.
 
 @param identifier The unique identifier of a running request.
 @return return The runing XMRequest/XMBatchRequest/XMChainRequest object (if exist) matching to identifier.
 */
- (nullable id)getRequest:(NSString *)identifier;

/**
 Method to get current network reachablity status.
 
 @return The network is reachable or not.
 */
- (BOOL)isNetworkReachable;

///--------------------------------
/// @name Class Method for XMCenter
///--------------------------------

// NOTE: The following class method is invoke through the `[XMCenter defaultCenter]` singleton object.

#pragma mark - Class Method

+ (void)setupConfig:(void(^)(XMConfig *config))block;
+ (void)setRequestProcessBlock:(XMCenterRequestProcessBlock)block;
+ (void)setResponseProcessBlock:(XMCenterResponseProcessBlock)block;
+ (void)setGeneralHeaderValue:(nullable NSString *)value forField:(NSString *)field;
+ (void)setGeneralParameterValue:(nullable id)value forKey:(NSString *)key;

#pragma mark -

+ (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock;

+ (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                         onSuccess:(nullable XMSuccessBlock)successBlock;

+ (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                         onFailure:(nullable XMFailureBlock)failureBlock;

+ (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                        onFinished:(nullable XMFinishedBlock)finishedBlock;

+ (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                         onSuccess:(nullable XMSuccessBlock)successBlock
                         onFailure:(nullable XMFailureBlock)failureBlock;

+ (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                         onSuccess:(nullable XMSuccessBlock)successBlock
                         onFailure:(nullable XMFailureBlock)failureBlock
                        onFinished:(nullable XMFinishedBlock)finishedBlock;

+ (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                        onProgress:(nullable XMProgressBlock)progressBlock
                         onSuccess:(nullable XMSuccessBlock)successBlock
                         onFailure:(nullable XMFailureBlock)failureBlock;

+ (nullable NSString *)sendRequest:(XMRequestConfigBlock)configBlock
                        onProgress:(nullable XMProgressBlock)progressBlock
                         onSuccess:(nullable XMSuccessBlock)successBlock
                         onFailure:(nullable XMFailureBlock)failureBlock
                        onFinished:(nullable XMFinishedBlock)finishedBlock;

+ (nullable NSString *)sendBatchRequest:(XMBatchRequestConfigBlock)configBlock
                              onSuccess:(nullable XMBCSuccessBlock)successBlock
                              onFailure:(nullable XMBCFailureBlock)failureBlock
                             onFinished:(nullable XMBCFinishedBlock)finishedBlock;

+ (nullable NSString *)sendChainRequest:(XMChainRequestConfigBlock)configBlock
                              onSuccess:(nullable XMBCSuccessBlock)successBlock
                              onFailure:(nullable XMBCFailureBlock)failureBlock
                             onFinished:(nullable XMBCFinishedBlock)finishedBlock;

#pragma mark -

+ (void)cancelRequest:(NSString *)identifier;

+ (void)cancelRequest:(NSString *)identifier
             onCancel:(nullable XMCancelBlock)cancelBlock;

+ (nullable id)getRequest:(NSString *)identifier;

+ (BOOL)isNetworkReachable;

#pragma mark -

+ (void)addSSLPinningURL:(NSString *)url;
+ (void)addSSLPinningCert:(NSData *)cert;
+ (void)addTwowayAuthenticationPKCS12:(NSData *)p12 keyPassword:(NSString *)password;

@end

#pragma mark - XMConfig

/**
 `XMConfig` is used to assign values for XMCenter's properties through invoking `-setupConfig:` method.
 */
@interface XMConfig : NSObject

///-----------------------------------------------
/// @name Properties to Assign Values for XMCenter
///-----------------------------------------------

/**
The general server address to assign for XMCenter.
*/
@property (nonatomic, copy, nullable) NSString *generalServer;

/**
 The general parameters to assign for XMCenter.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *generalParameters;

/**
 The general headers to assign for XMCenter.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *generalHeaders;

/**
 The general user info to assign for XMCenter.
 */
@property (nonatomic, strong, nullable) NSDictionary *generalUserInfo;

/**
 The dispatch callback queue to assign for XMCenter.
 */
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

/**
 The global requests engine to assign for XMCenter.
 */
@property (nonatomic, strong, nullable) XMEngine *engine;

/**
 The console log BOOL value to assign for XMCenter.
 */
@property (nonatomic, assign) BOOL consoleLog;

@end

NS_ASSUME_NONNULL_END
