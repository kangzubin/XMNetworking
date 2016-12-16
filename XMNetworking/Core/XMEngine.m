//
//  XMEngine.m
//  XMNetworking
//
//  Created by Zubin Kang on 12/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMEngine.h"
#import "XMRequest.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import <objc/runtime.h>

static dispatch_queue_t xm_request_completion_callback_queue() {
    static dispatch_queue_t _xm_request_completion_callback_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _xm_request_completion_callback_queue = dispatch_queue_create("com.xmnetworking.request.completion.callback.queue", DISPATCH_QUEUE_CONCURRENT);
    });
    return _xm_request_completion_callback_queue;
}

#pragma mark - XMRequest Binding

@implementation NSObject (BindingXMRequestForNSURLSessionTask)

static NSString * const kXMRequestBindingKey = @"kXMRequestBindingKey";

- (void)bindingRequest:(XMRequest *)request {
    objc_setAssociatedObject(self, (__bridge CFStringRef)kXMRequestBindingKey, request, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (XMRequest *)bindedRequest {
    XMRequest *request = objc_getAssociatedObject(self, (__bridge CFStringRef)kXMRequestBindingKey);
    return request;
}

@end

#pragma mark - XMEngine

@interface XMEngine (){
    dispatch_semaphore_t _lock;
}

@property (nonatomic, strong, readwrite) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong) AFJSONRequestSerializer *afJSONRequestSerializer;
@property (nonatomic, strong) AFPropertyListRequestSerializer *afPropertyListRequestSerializer;

@property (nonatomic, strong) AFJSONResponseSerializer *afJSONResponseSerializer;
@property (nonatomic, strong) AFXMLParserResponseSerializer *afXMLParserResponseSerializer;
@property (nonatomic, strong) AFPropertyListResponseSerializer *afPropertyListResponseSerializer;

@end

@implementation XMEngine

+ (instancetype)sharedEngine {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _lock = dispatch_semaphore_create(1);
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    return self;
}

+ (void)load {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

- (void)dealloc {
    if (_sessionManager) {
        [_sessionManager invalidateSessionCancelingTasks:YES];
    }
}

#pragma mark - Public Methods

- (NSUInteger)sendRequest:(XMRequest *)request
        completionHandler:(nullable XMCompletionHandler)completionHandler {
    if (request.requestType == kXMRequestNormal) {
        return [self xm_dataTaskWithRequest:request completionHandler:completionHandler];
    } else if (request.requestType == kXMRequestUpload) {
        return [self xm_uploadTaskWithRequest:request completionHandler:completionHandler];
    } else if (request.requestType == kXMRequestDownload) {
        return [self xm_downloadTaskWithRequest:request completionHandler:completionHandler];
    } else {
        NSAssert(NO, @"Unknown request type.");
        return 0;
    }
}

- (nullable XMRequest *)cancelRequestByIdentifier:(NSUInteger)identifier {
    if (identifier == 0) return nil;
    __block XMRequest *request = nil;
    XMLock();
    [self.sessionManager.tasks enumerateObjectsUsingBlock:^(NSURLSessionTask *task, NSUInteger idx, BOOL *stop) {
        if (task.taskIdentifier == identifier) {
            request = task.bindedRequest;
            [task cancel];
            *stop = YES;
        }
    }];
    XMUnlock();
    return request;
}

- (nullable XMRequest *)getRequestByIdentifier:(NSUInteger)identifier {
    if (identifier == 0) return nil;
    __block XMRequest *request = nil;
    XMLock();
    [self.sessionManager.tasks enumerateObjectsUsingBlock:^(NSURLSessionTask *task, NSUInteger idx, BOOL *stop) {
        if (task.taskIdentifier == identifier) {
            request = task.bindedRequest;
            *stop = YES;
        }
    }];
    XMUnlock();
    return request;
}

- (NSInteger)networkReachability {
    return [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
}

#pragma mark - Private Methods

- (NSUInteger)xm_dataTaskWithRequest:(XMRequest *)request
                   completionHandler:(XMCompletionHandler)completionHandler {
    NSString *httpMethod = nil;
    static dispatch_once_t onceToken;
    static NSArray *httpMethodArray = nil;
    dispatch_once(&onceToken, ^{
        httpMethodArray = @[@"GET", @"POST", @"HEAD", @"DELETE", @"PUT", @"PATCH"];
    });
    if (request.httpMethod >= 0 && request.httpMethod < httpMethodArray.count) {
        httpMethod = httpMethodArray[request.httpMethod];
    }
    NSAssert(httpMethod.length > 0, @"The HTTP method not found.");
    
    AFHTTPRequestSerializer *requestSerializer = [self xm_getRequestSerializer:request];
    
    NSError *serializationError = nil;
    NSMutableURLRequest *urlRequest = [requestSerializer requestWithMethod:httpMethod
                                                                 URLString:request.url
                                                                parameters:request.parameters
                                                                     error:&serializationError];
    
    if (serializationError) {
        if (completionHandler) {
            dispatch_async(xm_request_completion_callback_queue(), ^{
                completionHandler(nil, serializationError);
            });
        }
        return 0;
    }
    
    [self xm_processURLRequest:urlRequest byXMRequest:request];
    
    NSURLSessionDataTask *dataTask = nil;
    __weak __typeof(self)weakSelf = self;
    dataTask = [self.sessionManager dataTaskWithRequest:urlRequest
                                      completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf xm_processResponse:response
                                object:responseObject
                                 error:error
                               request:request
                     completionHandler:completionHandler];
    }];
    
    [dataTask bindingRequest:request];
    [request setIdentifier:dataTask.taskIdentifier];
    [dataTask resume];
    
    return request.identifier;
}

- (NSUInteger)xm_uploadTaskWithRequest:(XMRequest *)request
                      completionHandler:(XMCompletionHandler)completionHandler {
    
    AFHTTPRequestSerializer *requestSerializer = [self xm_getRequestSerializer:request];
    
    __block NSError *serializationError = nil;
    NSMutableURLRequest *urlRequest = [requestSerializer multipartFormRequestWithMethod:@"POST"
                                                                              URLString:request.url
                                                                             parameters:request.parameters
                                                              constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [request.uploadFormDatas enumerateObjectsUsingBlock:^(XMUploadFormData *obj, NSUInteger idx, BOOL *stop) {
            if (obj.fileData) {
                if (obj.fileName && obj.mimeType) {
                    [formData appendPartWithFileData:obj.fileData name:obj.name fileName:obj.fileName mimeType:obj.mimeType];
                } else {
                    [formData appendPartWithFormData:obj.fileData name:obj.name];
                }
            } else if (obj.fileURL) {
                NSError *fileError = nil;
                if (obj.fileName && obj.mimeType) {
                    [formData appendPartWithFileURL:obj.fileURL name:obj.name fileName:obj.fileName mimeType:obj.mimeType error:&fileError];
                } else {
                    [formData appendPartWithFileURL:obj.fileURL name:obj.name error:&fileError];
                }
                if (fileError) {
                    serializationError = fileError;
                    *stop = YES;
                }
            }
        }];
    } error:&serializationError];
    
    if (serializationError) {
        if (completionHandler) {
            dispatch_async(xm_request_completion_callback_queue(), ^{
                completionHandler(nil, serializationError);
            });
        }
        return 0;
    }
    
    [self xm_processURLRequest:urlRequest byXMRequest:request];
    
    NSURLSessionUploadTask *uploadTask = nil;
    __weak __typeof(self)weakSelf = self;
    uploadTask = [self.sessionManager uploadTaskWithStreamedRequest:urlRequest
                                                           progress:request.progressBlock
                                                  completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf xm_processResponse:response
                                object:responseObject
                                 error:error
                               request:request
                     completionHandler:completionHandler];
    }];
    
    [uploadTask bindingRequest:request];
    [request setIdentifier:uploadTask.taskIdentifier];
    [uploadTask resume];
    
    return request.identifier;
}

- (NSUInteger)xm_downloadTaskWithRequest:(XMRequest *)request
                       completionHandler:(XMCompletionHandler)completionHandler {
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request.url]];
    [self xm_processURLRequest:urlRequest byXMRequest:request];
    
    NSURL *downloadFileSavePath;
    BOOL isDirectory;
    if(![[NSFileManager defaultManager] fileExistsAtPath:request.downloadSavePath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    if (isDirectory) {
        NSString *fileName = [urlRequest.URL lastPathComponent];
        downloadFileSavePath = [NSURL fileURLWithPath:[NSString pathWithComponents:@[request.downloadSavePath, fileName]] isDirectory:NO];
    } else {
        downloadFileSavePath = [NSURL fileURLWithPath:request.downloadSavePath isDirectory:NO];
    }
    
    NSURLSessionDownloadTask *downloadTask = nil;
    downloadTask = [self.sessionManager downloadTaskWithRequest:urlRequest
                                                       progress:request.progressBlock
                                                    destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                                        return downloadFileSavePath;
                                                    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                        if (completionHandler) {
                                                            completionHandler(filePath, error);
                                                        }
                                                    }];
    
    [downloadTask bindingRequest:request];
    [request setIdentifier:downloadTask.taskIdentifier];
    [downloadTask resume];
    
    return request.identifier;
}

- (void)xm_processURLRequest:(NSMutableURLRequest *)urlRequest byXMRequest:(XMRequest *)request {
    if (request.headers.count > 0) {
        [request.headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
            //if (![urlRequest valueForHTTPHeaderField:field]) {
                [urlRequest setValue:value forHTTPHeaderField:field];
            //}
        }];
    }
    urlRequest.timeoutInterval = request.timeoutInterval;
}

- (void)xm_processResponse:(NSURLResponse *)response
                    object:(id)responseObject
                     error:(NSError *)error
                   request:(XMRequest *)request
         completionHandler:(XMCompletionHandler)completionHandler {
    NSError *serializationError = nil;
    if (request.responseSerializerType != kXMResponseSerializerRAW) {
        AFHTTPResponseSerializer *responseSerializer = [self xm_getResponseSerializer:request];
        responseObject = [responseSerializer responseObjectForResponse:response data:responseObject error:&serializationError];
    }
    
    if (completionHandler) {
        if (serializationError) {
            completionHandler(nil, serializationError);
        } else {
            completionHandler(responseObject, error);
        }
    }
}

- (AFHTTPRequestSerializer *)xm_getRequestSerializer:(XMRequest *)request {
    if (request.requestSerializerType == kXMRequestSerializerRAW) {
        return self.sessionManager.requestSerializer;
    } else if(request.requestSerializerType == kXMRequestSerializerJSON) {
        return self.afJSONRequestSerializer;
    } else if (request.requestSerializerType == kXMRequestSerializerPlist) {
        return self.afPropertyListRequestSerializer;
    } else {
        NSAssert(NO, @"Unknown request serializer type.");
        return nil;
    }
}

- (AFHTTPResponseSerializer *)xm_getResponseSerializer:(XMRequest *)request {
    if (request.responseSerializerType == kXMResponseSerializerRAW) {
        return self.sessionManager.responseSerializer;
    } else if (request.responseSerializerType == kXMResponseSerializerJSON) {
        return self.afJSONResponseSerializer;
    } else if (request.responseSerializerType == kXMResponseSerializerPlist) {
        return self.afPropertyListResponseSerializer;
    } else if (request.responseSerializerType == kXMResponseSerializerXML) {
        return self.afXMLParserResponseSerializer;
    } else {
        NSAssert(NO, @"Unknown response serializer type.");
        return nil;
    }
}

#pragma mark - Accessor

- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _sessionManager.operationQueue.maxConcurrentOperationCount = 5;
        _sessionManager.completionQueue = xm_request_completion_callback_queue();
    }
    return _sessionManager;
}

- (AFJSONRequestSerializer *)afJSONRequestSerializer {
    if (!_afJSONRequestSerializer) {
        _afJSONRequestSerializer = [AFJSONRequestSerializer serializer];
        
    }
    return _afJSONRequestSerializer;
}

- (AFPropertyListRequestSerializer *)afPropertyListRequestSerializer {
    if (!_afPropertyListRequestSerializer) {
        _afPropertyListRequestSerializer = [AFPropertyListRequestSerializer serializer];
    }
    return _afPropertyListRequestSerializer;
}

- (AFJSONResponseSerializer *)afJSONResponseSerializer {
    if (!_afJSONResponseSerializer) {
        _afJSONResponseSerializer = [AFJSONResponseSerializer serializer];
        // Append more other commonly-used types to the JSON responses accepted MIME types.
        _afJSONResponseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", nil];
        
    }
    return _afJSONResponseSerializer;
}

- (AFXMLParserResponseSerializer *)afXMLParserResponseSerializer {
    if (!_afXMLParserResponseSerializer) {
        _afXMLParserResponseSerializer = [AFXMLParserResponseSerializer serializer];
    }
    return _afXMLParserResponseSerializer;
}

- (AFPropertyListResponseSerializer *)afPropertyListResponseSerializer {
    if (!_afPropertyListResponseSerializer) {
        _afPropertyListResponseSerializer = [AFPropertyListResponseSerializer serializer];
    }
    return _afPropertyListResponseSerializer;
}

@end
