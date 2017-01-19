//
//  XMConst.h
//  XMNetworking
//
//  Created by Zubin Kang on 12/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#ifndef XMConst_h
#define XMConst_h

#define XM_SAFE_BLOCK(BlockName, ...) ({ !BlockName ? nil : BlockName(__VA_ARGS__); })
#define XMLock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define XMUnlock() dispatch_semaphore_signal(self->_lock)

NS_ASSUME_NONNULL_BEGIN

@class XMRequest, XMBatchRequest, XMChainRequest;

/**
 Types enum for XMRequest.
 */
typedef NS_ENUM(NSInteger, XMRequestType) {
    kXMRequestNormal    = 0,    //!< Normal HTTP request type, such as GET, POST, ...
    kXMRequestUpload    = 1,    //!< Upload request type
    kXMRequestDownload  = 2,    //!< Download request type
};

/**
 HTTP methods enum for XMRequest.
 */
typedef NS_ENUM(NSInteger, XMHTTPMethodType) {
    kXMHTTPMethodGET    = 0,    //!< GET
    kXMHTTPMethodPOST   = 1,    //!< POST
    kXMHTTPMethodHEAD   = 2,    //!< HEAD
    kXMHTTPMethodDELETE = 3,    //!< DELETE
    kXMHTTPMethodPUT    = 4,    //!< PUT
    kXMHTTPMethodPATCH  = 5,    //!< PATCH
};

/**
 Resquest parameter serialization type enum for XMRequest, see `AFURLRequestSerialization.h` for details.
 */
typedef NS_ENUM(NSInteger, XMRequestSerializerType) {
    kXMRequestSerializerRAW     = 0,    //!< Encodes parameters to a query string and put it into HTTP body, setting the `Content-Type` of the encoded request to default value `application/x-www-form-urlencoded`.
    kXMRequestSerializerJSON    = 1,    //!< Encodes parameters as JSON using `NSJSONSerialization`, setting the `Content-Type` of the encoded request to `application/json`.
    kXMRequestSerializerPlist   = 2,    //!< Encodes parameters as Property List using `NSPropertyListSerialization`, setting the `Content-Type` of the encoded request to `application/x-plist`.
};

/**
 Response data serialization type enum for XMRequest, see `AFURLResponseSerialization.h` for details.
 */
typedef NS_ENUM(NSInteger, XMResponseSerializerType) {
    kXMResponseSerializerRAW    = 0,    //!< Validates the response status code and content type, and returns the default response data.
    kXMResponseSerializerJSON   = 1,    //!< Validates and decodes JSON responses using `NSJSONSerialization`, and returns a NSDictionary/NSArray/... JSON object.
    kXMResponseSerializerPlist  = 2,    //!< Validates and decodes Property List responses using `NSPropertyListSerialization`, and returns a property list object.
    kXMResponseSerializerXML    = 3,    //!< Validates and decodes XML responses as an `NSXMLParser` objects.
};

///------------------------------
/// @name XMRequest Config Blocks
///------------------------------

typedef void (^XMRequestConfigBlock)(XMRequest *request);
typedef void (^XMBatchRequestConfigBlock)(XMBatchRequest *batchRequest);
typedef void (^XMChainRequestConfigBlock)(XMChainRequest *chainRequest);

///--------------------------------
/// @name XMRequest Callback Blocks
///--------------------------------

typedef void (^XMProgressBlock)(NSProgress *progress);
typedef void (^XMSuccessBlock)(id _Nullable responseObject);
typedef void (^XMFailureBlock)(NSError * _Nullable error);
typedef void (^XMFinishedBlock)(id _Nullable responseObject, NSError * _Nullable error);
typedef void (^XMCancelBlock)(id _Nullable request); // The `request` might be a XMRequest/XMBatchRequest/XMChainRequest object.

///-------------------------------------------------
/// @name Callback Blocks for Batch or Chain Request
///-------------------------------------------------

typedef void (^XMBCSuccessBlock)(NSArray *responseObjects);
typedef void (^XMBCFailureBlock)(NSArray *errors);
typedef void (^XMBCFinishedBlock)(NSArray * _Nullable responseObjects, NSArray * _Nullable errors);
typedef void (^XMBCNextBlock)(XMRequest *request, id _Nullable responseObject, BOOL *isSent);

///------------------------------
/// @name XMCenter Process Blocks
///------------------------------

/**
 The custom request pre-process block for all XMRequests invoked by XMCenter.
 
 @param request The current XMRequest object.
 */
typedef void (^XMCenterRequestProcessBlock)(XMRequest *request);

/**
 The custom response process block for all XMRequests invoked by XMCenter.

 @param request The current XMRequest object.
 @param responseObject The response data return from server.
 @param error The error that occurred while the response data don't conforms to your own business logic.
 */
typedef void (^XMCenterResponseProcessBlock)(XMRequest *request, id _Nullable responseObject, NSError * _Nullable __autoreleasing *error);

NS_ASSUME_NONNULL_END

#endif /* XMConst_h */
