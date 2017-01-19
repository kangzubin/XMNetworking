//
//  XMRequest.h
//  XMNetworking
//
//  Created by Zubin Kang on 12/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMConst.h"

NS_ASSUME_NONNULL_BEGIN

@class XMUploadFormData;

/**
 `XMRequest` is the base class for all network requests invoked by XMCenter.
 */
@interface XMRequest : NSObject

/**
 Creates and returns a new `XMRequest` object.
 */
+ (instancetype)request;

/**
 The unique identifier for a XMRequest object, the value is assigned by XMCenter when the request is sent.
 */
@property (nonatomic, copy, readonly) NSString *identifier;

/**
 The server address for request, eg. "http://example.com/v1/", if `nil` (default) and the `useGeneralServer` property is `YES` (default), the `generalServer` of XMCenter is used.
 */
@property (nonatomic, copy, nullable) NSString *server;

/**
 The API interface path for request, eg. "foo/bar", `nil` by default.
 */
@property (nonatomic, copy, nullable) NSString *api;

/**
 The final URL of request, which is combined by `server` and `api` properties, eg. "http://example.com/v1/foo/bar", `nil` by default.
 NOTE: when you manually set the value for `url`, the `server` and `api` properties will be ignored.
 */
@property (nonatomic, copy, nullable) NSString *url;

/**
 The parameters for request, if `useGeneralParameters` property is `YES` (default), the `generalParameters` of XMCenter will be appended to the `parameters`.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *parameters;

/**
 The HTTP headers for request, if `useGeneralHeaders` property is `YES` (default), the `generalHeaders` of XMCenter will be appended to the `headers`.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *headers;

@property (nonatomic, assign) BOOL useGeneralServer;        //!< Whether or not to use `generalServer` of XMCenter when request `server` is `nil`, `YES` by default.
@property (nonatomic, assign) BOOL useGeneralHeaders;       //!< Whether or not to append `generalHeaders` of XMCenter to request `headers`, `YES` by default.
@property (nonatomic, assign) BOOL useGeneralParameters;    //!< Whether or not to append `generalParameters` of XMCenter to request `parameters`, `YES` by default.

/**
 Type for request: Normal, Upload or Download, `kXMRequestNormal` by default.
 */
@property (nonatomic, assign) XMRequestType requestType;

/**
 HTTP method for request, `kXMHTTPMethodPOST` by default, see `XMHTTPMethodType` enum for details.
 */
@property (nonatomic, assign) XMHTTPMethodType httpMethod;

/**
 Parameter serialization type for request, `kXMRequestSerializerRAW` by default, see `XMRequestSerializerType` enum for details.
 */
@property (nonatomic, assign) XMRequestSerializerType requestSerializerType;

/**
 Response data serialization type for request, `kXMResponseSerializerJSON` by default, see `XMResponseSerializerType` enum for details.
 */
@property (nonatomic, assign) XMResponseSerializerType responseSerializerType;

/**
 Timeout interval for request, `60` seconds by default.
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 The retry count for current request when error occurred, `0` by default.
 */
@property (nonatomic, assign) NSUInteger retryCount;

/**
 User info for current request, which could be used to distinguish requests with same context, if `nil` (default), the `generalUserInfo` of XMCenter is used.
 */
@property (nonatomic, strong, nullable) NSDictionary *userInfo;

/**
 Success block for request, called when current request completed successful, the block will execute in `callbackQueue` of XMCenter.
 */
@property (nonatomic, copy, readonly, nullable) XMSuccessBlock successBlock;

/**
 Failure block for request, called when error occurred, the block will execute in `callbackQueue` of XMCenter.
 */
@property (nonatomic, copy, readonly, nullable) XMFailureBlock failureBlock;

/**
 Finished block for request, called when current request is finished, the block will execute in `callbackQueue` of XMCenter.
 */
@property (nonatomic, copy, readonly, nullable) XMFinishedBlock finishedBlock;

/**
 Progress block for upload/download request, called when the upload/download progress is updated,
 NOTE: This block is called on the session queue, not the `callbackQueue` of XMCenter !!!
 */
@property (nonatomic, copy, readonly, nullable) XMProgressBlock progressBlock;

/**
 Nil out all callback blocks when a request is finished to break the potential retain cycle.
 */
- (void)cleanCallbackBlocks;

/**
 Upload files form data for upload request, `nil` by default, see `XMUploadFormData` class and `AFMultipartFormData` protocol for details.
 NOTE: This property is effective only when `requestType` is assigned to `kXMRequestUpload`.
 */
@property (nonatomic, strong, nullable) NSMutableArray<XMUploadFormData *> *uploadFormDatas;

/**
 Local save path for downloaded file, `nil` by default.
 NOTE: This property is effective only when `requestType` is assigned to `kXMRequestDownload`.
 */
@property (nonatomic, copy, nullable) NSString *downloadSavePath;

///----------------------------------------------------
/// @name Quickly Methods For Add Upload File Form Data
///----------------------------------------------------

- (void)addFormDataWithName:(NSString *)name fileData:(NSData *)fileData;
- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData;
- (void)addFormDataWithName:(NSString *)name fileURL:(NSURL *)fileURL;
- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL;

@end

#pragma mark - XMBatchRequest

///------------------------------------------------------
/// @name XMBatchRequest Class for sending batch requests
///------------------------------------------------------

@interface XMBatchRequest : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) NSMutableArray *requestArray;
@property (nonatomic, strong, readonly) NSMutableArray *responseArray;

- (BOOL)onFinishedOneRequest:(XMRequest *)request response:(nullable id)responseObject error:(nullable NSError *)error;

@end

#pragma mark - XMChainRequest

///------------------------------------------------------
/// @name XMChainRequest Class for sending chain requests
///------------------------------------------------------

@interface XMChainRequest : NSObject

@property (nonatomic, copy, readonly) NSString *identifier;
@property (nonatomic, strong, readonly) XMRequest *runningRequest;

- (XMChainRequest *)onFirst:(XMRequestConfigBlock)firstBlock;
- (XMChainRequest *)onNext:(XMBCNextBlock)nextBlock;

- (BOOL)onFinishedOneRequest:(XMRequest *)request response:(nullable id)responseObject error:(nullable NSError *)error;

@end

#pragma mark - XMUploadFormData

/**
 `XMUploadFormData` is the class for describing and carring the upload file data, see `AFMultipartFormData` protocol for details.
 */
@interface XMUploadFormData : NSObject

/**
 The name to be associated with the specified data. This property must not be `nil`.
 */
@property (nonatomic, copy) NSString *name;

/**
 The file name to be used in the `Content-Disposition` header. This property is not recommended be `nil`.
 */
@property (nonatomic, copy, nullable) NSString *fileName;

/**
 The declared MIME type of the file data. This property is not recommended be `nil`.
 */
@property (nonatomic, copy, nullable) NSString *mimeType;

/**
 The data to be encoded and appended to the form data, and it is prior than `fileURL`.
 */
@property (nonatomic, strong, nullable) NSData *fileData;

/**
 The URL corresponding to the file whose content will be appended to the form, BUT, when the `fileData` is assigned，the `fileURL` will be ignored.
 */
@property (nonatomic, strong, nullable) NSURL *fileURL;

// NOTE: Either of the `fileData` and `fileURL` should not be `nil`, and the `fileName` and `mimeType` must both be `nil` or assigned at the same time,

///-----------------------------------------------------
/// @name Quickly Class Methods For Creates A New Object
///-----------------------------------------------------

+ (instancetype)formDataWithName:(NSString *)name fileData:(NSData *)fileData;
+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData;
+ (instancetype)formDataWithName:(NSString *)name fileURL:(NSURL *)fileURL;
+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL;

@end

NS_ASSUME_NONNULL_END
