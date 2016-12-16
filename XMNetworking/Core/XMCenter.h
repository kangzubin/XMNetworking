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

@class XMConfig;

/**
 `XMCenter` is a global central place to send and manage network requests.
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
 
 [XMCenter setResponseProcessBlock:^(XMRequest *request, id responseObject, NSError *__autoreleasing *error) {
     // Do the custom response data processing logic by yourself,
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

// NOTE: The following properties will be assigned by `XMConfig` through invoking `-setupConfig:` method.

/**
 The general server address for XMCenter, if XMRequest.server is `nil` and the XMRequest.useGeneralServer is `YES`, this property will be assigned to XMRequest.server.
 */
@property (nonatomic, copy, nullable, readonly) NSString *generalServer;

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
 Whether to print the request and response info in console or not, `NO` by default.
 */
@property (nonatomic, assign) BOOL consoleLog;

///--------------------------------------------
/// @name Instance Method to Configure XMCenter
///--------------------------------------------

/**
 Method to config the XMCenter properties by a `XMConfig` object.

 @param block The config block to assign the values for `XMConfig` object.
 */
- (void)setupConfig:(void(^)(XMConfig *config))block;

/**
 Method to set custom response data processing block for XMCenter.

 @param block The custom processing block (`XMCenterResponseProcessBlock`).
 */
- (void)setResponseProcessBlock:(XMCenterResponseProcessBlock)block;

///---------------------------------------
/// @name Instance Method to Send Requests
///---------------------------------------

/**
 Creates and runs a Normal `XMRequest`.

 @param configBlock The config block to setup context info for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`0` for fail.
 */
- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock;

/**
 Creates and runs a Normal `XMRequest` with success block.
 
 NOTE: The success block will be called on `callbackQueue` of XMCenter.

 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param successBlock Success callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`0` for fail.
 */
- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock;

/**
 Creates and runs a Normal `XMRequest` with failure block.
 
 NOTE: The failure block will be called on `callbackQueue` of XMCenter.

 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param failureBlock Failure callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`0` for fail.
 */
- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onFailure:(nullable XMFailureBlock)failureBlock;

/**
 Creates and runs a Normal `XMRequest` with finished block.

 NOTE: The finished block will be called on `callbackQueue` of XMCenter.
 
 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param finishedBlock Finished callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`0` for fail.
 */
- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
               onFinished:(nullable XMFinishedBlock)finishedBlock;

/**
 Creates and runs a Normal `XMRequest` with success/failure blocks.

 NOTE: The success/failure blocks will be called on `callbackQueue` of XMCenter.
 
 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param successBlock Success callback block for the new created XMRequest object.
 @param failureBlock Failure callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`0` for fail.
 */
- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock;

/**
 Creates and runs a Normal `XMRequest` with success/failure/finished blocks.

 NOTE: The success/failure/finished blocks will be called on `callbackQueue` of XMCenter.
 
 @param configBlock The config block to setup context info for the new created XMRequest object.
 @param successBlock Success callback block for the new created XMRequest object.
 @param failureBlock Failure callback block for the new created XMRequest object.
 @param finishedBlock Finished callback block for the new created XMRequest object.
 @return Unique identifier for the new running XMRequest object,`0` for fail.
 */
- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
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
 @return Unique identifier for the new running XMRequest object,`0` for fail.
 */
- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
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
 @return Unique identifier for the new running XMRequest object,`0` for fail.
 */
- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
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
 @return The new running XMBatchRequest object, the object might be used to cancel the batch requests.
 */
- (nullable XMBatchRequest *)sendBatchRequest:(XMBatchRequestConfigBlock)configBlock
                                    onSuccess:(nullable XMBatchSuccessBlock)successBlock
                                    onFailure:(nullable XMBatchFailureBlock)failureBlock
                                   onFinished:(nullable XMBatchFinishedBlock)finishedBlock;

/**
 Creates and runs chain requests

 @param configBlock The config block to setup chain requests context info for the new created XMBatchRequest object.
 @param successBlock Success callback block called when all chain requests finished successfully.
 @param failureBlock Failure callback block called once a request error occured.
 @param finishedBlock Finished callback block for the new created XMChainRequest object.
 @return The new running XMChainRequest object, the object might be used to cancel the chain requests.
 */
- (nullable XMChainRequest *)sendChainRequest:(XMChainRequestConfigBlock)configBlock
                                    onSuccess:(nullable XMBatchSuccessBlock)successBlock
                                    onFailure:(nullable XMBatchFailureBlock)failureBlock
                                   onFinished:(nullable XMBatchFinishedBlock)finishedBlock;

///---------------------------------------------------------
/// @name Class Method to Configure [XMCenter defaultCenter]
///---------------------------------------------------------

+ (void)setupConfig:(void(^)(XMConfig *config))block;
+ (void)setResponseProcessBlock:(XMCenterResponseProcessBlock)block;

/**
 Sets the value for the general HTTP headers of [XMCenter defaultCenter], If `nil`, removes the existing value for that header.

 @param value The value to set for the specified header, or `nil`.
 @param field The HTTP header to set a value for.
 */
+ (void)setGeneralHeaderValue:(nullable NSString *)value forField:(NSString *)field;

/**
 Sets the value for the general parameters of [XMCenter defaultCenter], If `nil`, removes the existing value for that parameter.

 @param value The value to set for the specified parameter, or `nil`.
 @param key The parameter key to set a value for.
 */
+ (void)setGeneralParameterValue:(nullable NSString *)value forKey:(NSString *)key;

///------------------------------------
/// @name Class Method to Send Requests
///------------------------------------

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock;

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock;

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onFailure:(nullable XMFailureBlock)failureBlock;

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
               onFinished:(nullable XMFinishedBlock)finishedBlock;

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock;

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock
               onFinished:(nullable XMFinishedBlock)finishedBlock;

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
               onProgress:(nullable XMProgressBlock)progressBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock;

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
               onProgress:(nullable XMProgressBlock)progressBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock
               onFinished:(nullable XMFinishedBlock)finishedBlock;

+ (nullable XMBatchRequest *)sendBatchRequest:(XMBatchRequestConfigBlock)configBlock
                                    onSuccess:(nullable XMBatchSuccessBlock)successBlock
                                    onFailure:(nullable XMBatchFailureBlock)failureBlock
                                   onFinished:(nullable XMBatchFinishedBlock)finishedBlock;

+ (nullable XMChainRequest *)sendChainRequest:(XMChainRequestConfigBlock)configBlock
                                    onSuccess:(nullable XMBatchSuccessBlock)successBlock
                                    onFailure:(nullable XMBatchFailureBlock)failureBlock
                                   onFinished:(nullable XMBatchFinishedBlock)finishedBlock;

///-------------------------------------------------------
/// @name Class Methods to Get Or Cancel a Running Request
///-------------------------------------------------------

/**
 Method to cancel a runnig request by identifier.

 @param identifier The unique identifier of a running request.
 */
+ (void)cancelRequest:(NSUInteger)identifier;

/**
 Method to cancel a runnig request by identifier with cancel block.
 
 NOTE: The cancel block is called on current thread who invoked the method, not the `callbackQueue` of XMCenter.
 
 @param identifier The unique identifier of a running request.
 @param cancelBlock The callback block to be executed after the running request is canceled. The canceled request object (if exist) will be passed in argument to the cancel block.
 */
+ (void)cancelRequest:(NSUInteger)identifier
             onCancel:(nullable XMCancelBlock)cancelBlock;

/**
 Method to get a runnig request object matching to identifier.
 
 @param identifier The unique identifier of a running request.
 @return return The runing requset object (if exist) matching to identifier.
 */
+ (nullable XMRequest *)getRequest:(NSUInteger)identifier;

/**
 Method to get current network reachablity status.

 @return The network is reachable or not.
 */
+ (BOOL)isNetworkReachable;

@end

#pragma mark - XMConfig

/**
 `XMConfig` is used to assign values for XMCenter through invoking `-setupConfig:` method.
 */
@interface XMConfig : NSObject

///-----------------------------------------------
/// @name Properties to Assign Values for XMCenter
///-----------------------------------------------

@property (nonatomic, copy, nullable) NSString *generalServer;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *generalParameters;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *generalHeaders;
@property (nonatomic, strong, nullable) NSDictionary *generalUserInfo;
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;
@property (nonatomic, assign) BOOL consoleLog;

@end

NS_ASSUME_NONNULL_END
