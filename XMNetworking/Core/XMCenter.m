//
//  XMCenter.m
//  XMNetworking
//
//  Created by Zubin Kang on 12/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMCenter.h"
#import "XMRequest.h"
#import "XMEngine.h"

@interface XMCenter ()

@property (nonatomic, copy, nullable, readwrite) NSString *generalServer;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, id> *generalParameters;
@property (nonatomic, strong, readwrite) NSMutableDictionary<NSString *, NSString *> *generalHeaders;

@property (nonatomic, copy) XMCenterResponseProcessBlock responseProcessHandler;

@end

@implementation XMCenter

+ (instancetype)center {
    return [[[self class] alloc] init];
}

+ (instancetype)defaultCenter {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self center];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    return self;
}

#pragma mark - Public Instance Methods for XMCenter

- (void)setupConfig:(void(^)(XMConfig *config))block {
    XMConfig *config = [[XMConfig alloc] init];
    config.consoleLog = NO;
    XM_SAFE_BLOCK(block, config);
    
    if (config.generalServer) {
        self.generalServer = config.generalServer;
    }
    if (config.generalParameters.count > 0) {
        [self.generalParameters addEntriesFromDictionary:config.generalParameters];
    }
    if (config.generalHeaders.count > 0) {
        [self.generalHeaders addEntriesFromDictionary:config.generalHeaders];
    }
    if (config.callbackQueue != NULL) {
        self.callbackQueue = config.callbackQueue;
    }
    if (config.generalUserInfo) {
        self.generalUserInfo = config.generalUserInfo;
    }
    self.consoleLog = config.consoleLog;
}

- (void)setResponseProcessBlock:(XMCenterResponseProcessBlock)block {
    self.responseProcessHandler = block;
}

- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:nil];
}

- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:nil onFinished:nil];
}

- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onFailure:(nullable XMFailureBlock)failureBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:failureBlock onFinished:nil];
}

- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
               onFinished:(nullable XMFinishedBlock)finishedBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:finishedBlock];
}

- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock
               onFinished:(nullable XMFinishedBlock)finishedBlock {
    return [self sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
               onProgress:(nullable XMProgressBlock)progressBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock {
    return [self sendRequest:configBlock onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

- (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
               onProgress:(nullable XMProgressBlock)progressBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock
               onFinished:(nullable XMFinishedBlock)finishedBlock {
    XMRequest *request = [XMRequest request];
    XM_SAFE_BLOCK(configBlock, request);
    
    [self xm_processRequest:request onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
    
    return [self xm_sendRequest:request];
}

- (XMBatchRequest *)sendBatchRequest:(XMBatchRequestConfigBlock)configBlock
                           onSuccess:(nullable XMBatchSuccessBlock)successBlock
                           onFailure:(nullable XMBatchFailureBlock)failureBlock
                          onFinished:(nullable XMBatchFinishedBlock)finishedBlock {
    XMBatchRequest *batchRequest = [[XMBatchRequest alloc] init];
    XM_SAFE_BLOCK(configBlock, batchRequest);
    
    if (batchRequest.requestArray.count > 0) {
        if (successBlock) {
            [batchRequest setValue:successBlock forKey:@"_batchSuccessBlock"];
        }
        if (failureBlock) {
            [batchRequest setValue:failureBlock forKey:@"_batchFailureBlock"];
        }
        if (finishedBlock) {
            [batchRequest setValue:finishedBlock forKey:@"_batchFinishedBlock"];
        }
        
        [batchRequest.responseArray removeAllObjects];
        for (XMRequest *request in batchRequest.requestArray) {
            [batchRequest.responseArray addObject:[NSNull null]];
            [self xm_processRequest:request
                         onProgress:nil
                          onSuccess:nil
                          onFailure:nil
                         onFinished:^(id responseObject, NSError *error) {
                             [batchRequest onFinishedOneRequest:request response:responseObject error:error];
                         }];
            [self xm_sendRequest:request];
        }
        return batchRequest;
    } else {
        return nil;
    }
}

- (XMChainRequest *)sendChainRequest:(XMChainRequestConfigBlock)configBlock
                           onSuccess:(nullable XMBatchSuccessBlock)successBlock
                           onFailure:(nullable XMBatchFailureBlock)failureBlock
                          onFinished:(nullable XMBatchFinishedBlock)finishedBlock {
    XMChainRequest *chainRequest = [[XMChainRequest alloc] init];
    XM_SAFE_BLOCK(configBlock, chainRequest);
    
    if (chainRequest.firstRequest) {
        if (successBlock) {
            [chainRequest setValue:successBlock forKey:@"_chainSuccessBlock"];
        }
        if (failureBlock) {
            [chainRequest setValue:failureBlock forKey:@"_chainFailureBlock"];
        }
        if (finishedBlock) {
            [chainRequest setValue:finishedBlock forKey:@"_chainFinishedBlock"];
        }
        
        [self xm_sendChainRequest:chainRequest withRequest:chainRequest.firstRequest];
        return chainRequest;
    } else {
        return nil;
    }
}

#pragma mark - Public Class Methods for XMCenter

+ (void)setupConfig:(void(^)(XMConfig *config))block {
    [[XMCenter defaultCenter] setupConfig:block];
}

+ (void)setResponseProcessBlock:(XMCenterResponseProcessBlock)block {
    [[XMCenter defaultCenter] setResponseProcessBlock:block];
}

+ (void)setGeneralHeaderValue:(nullable NSString *)value forField:(NSString *)field {
    [[XMCenter defaultCenter].generalHeaders setValue:value forKey:field];
}

+ (void)setGeneralParameterValue:(nullable NSString *)value forKey:(NSString *)key {
    [[XMCenter defaultCenter].generalParameters setValue:value forKey:key];
}

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock {
    return [[XMCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:nil];
}

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock {
    return [[XMCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:nil onFinished:nil];
}

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onFailure:(nullable XMFailureBlock)failureBlock {
    return [[XMCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:failureBlock onFinished:nil];
}

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
               onFinished:(nullable XMFinishedBlock)finishedBlock {
    return [[XMCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:nil onFailure:nil onFinished:finishedBlock];
}

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock {
    return [[XMCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock
               onFinished:(nullable XMFinishedBlock)finishedBlock {
    return [[XMCenter defaultCenter] sendRequest:configBlock onProgress:nil onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
               onProgress:(nullable XMProgressBlock)progressBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock {
    return [[XMCenter defaultCenter] sendRequest:configBlock onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:nil];
}

+ (NSUInteger)sendRequest:(XMRequestConfigBlock)configBlock
               onProgress:(nullable XMProgressBlock)progressBlock
                onSuccess:(nullable XMSuccessBlock)successBlock
                onFailure:(nullable XMFailureBlock)failureBlock
               onFinished:(nullable XMFinishedBlock)finishedBlock {
    return [[XMCenter defaultCenter] sendRequest:configBlock onProgress:progressBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (XMBatchRequest *)sendBatchRequest:(XMBatchRequestConfigBlock)configBlock
                           onSuccess:(nullable XMBatchSuccessBlock)successBlock
                           onFailure:(nullable XMBatchFailureBlock)failureBlock
                          onFinished:(nullable XMBatchFinishedBlock)finishedBlock {
    return [[XMCenter defaultCenter] sendBatchRequest:configBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (XMChainRequest *)sendChainRequest:(XMChainRequestConfigBlock)configBlock
                           onSuccess:(nullable XMBatchSuccessBlock)successBlock
                           onFailure:(nullable XMBatchFailureBlock)failureBlock
                          onFinished:(nullable XMBatchFinishedBlock)finishedBlock {
    return [[XMCenter defaultCenter] sendChainRequest:configBlock onSuccess:successBlock onFailure:failureBlock onFinished:finishedBlock];
}

+ (void)cancelRequest:(NSUInteger)identifier {
    [self cancelRequest:identifier onCancel:nil];
}

+ (void)cancelRequest:(NSUInteger)identifier
             onCancel:(nullable XMCancelBlock)cancelBlock {
    XMRequest *request = [[XMEngine sharedEngine] cancelRequestByIdentifier:identifier];
    XM_SAFE_BLOCK(cancelBlock, request);
}

+ (nullable XMRequest *)getRequest:(NSUInteger)identifier {
    return [[XMEngine sharedEngine]getRequestByIdentifier:identifier];
}

+ (BOOL)isNetworkReachable {
    return [XMEngine sharedEngine].networkReachability != 0;
}

#pragma mark - Private Methods for XMCenter

- (void)xm_sendChainRequest:(XMChainRequest *)chainRequest withRequest:(XMRequest *)request {
    __weak __typeof(self)weakSelf = self;
    [self xm_processRequest:request
                 onProgress:nil
                  onSuccess:nil
                  onFailure:nil
                 onFinished:^(id responseObject, NSError *error) {
                     __strong __typeof(weakSelf)strongSelf = weakSelf;
                     [chainRequest onFinishedOneRequest:request response:responseObject error:error];
                     if (chainRequest.nextRequest) {
                         [strongSelf xm_sendChainRequest:chainRequest withRequest:chainRequest.nextRequest];
                     }
                 }];
    
    [self xm_sendRequest:request];
}

- (void)xm_processRequest:(XMRequest *)request
               onProgress:(XMProgressBlock)progressBlock
                onSuccess:(XMSuccessBlock)successBlock
                onFailure:(XMFailureBlock)failureBlock
               onFinished:(XMFinishedBlock)finishedBlock {
    
    // set callback blocks for the request object.
    if (successBlock) {
        [request setValue:successBlock forKey:@"_successBlock"];
    }
    if (failureBlock) {
        [request setValue:failureBlock forKey:@"_failureBlock"];
    }
    if (finishedBlock) {
        [request setValue:finishedBlock forKey:@"_finishedBlock"];
    }
    if (progressBlock && request.requestType != kXMRequestNormal) {
        [request setValue:progressBlock forKey:@"_progressBlock"];
    }
    
    // add general user info to the request object.
    if (!request.userInfo && self.generalUserInfo) {
        request.userInfo = self.generalUserInfo;
    }
    
    // add general parameters to the request object.
    if (request.useGeneralParameters && self.generalParameters.count > 0) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        [parameters addEntriesFromDictionary:self.generalParameters];
        if (request.parameters.count > 0) {
            [parameters addEntriesFromDictionary:request.parameters];
        }
        request.parameters = parameters;
    }
    
    // add general headers to the request object.
    if (request.useGeneralHeaders && self.generalHeaders.count > 0) {
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers addEntriesFromDictionary:self.generalHeaders];
        if (request.headers) {
            [headers addEntriesFromDictionary:request.headers];
        }
        request.headers = headers;
    }
    
    // process url for the request object.
    if (request.url.length == 0) {
        if (request.server.length == 0 && request.useGeneralServer && self.generalServer.length > 0) {
            request.server = self.generalServer;
        }
        if (request.api.length > 0) {
            NSURL *baseURL = [NSURL URLWithString:request.server];
            // ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected.
            if ([[baseURL path] length] > 0 && ![[baseURL absoluteString] hasSuffix:@"/"]) {
                baseURL = [baseURL URLByAppendingPathComponent:@""];
            }
            request.url = [[NSURL URLWithString:request.api relativeToURL:baseURL] absoluteString];
        } else {
            request.url = request.server;
        }
    }
    NSAssert(request.url.length > 0, @"The request url can't be null.");
}

- (NSUInteger)xm_sendRequest:(XMRequest *)request {
    
    if (self.consoleLog) {
        if (request.requestType == kXMRequestDownload) {
            NSLog(@"\n============ [XMRequest Info] ============\nrequest download url: %@\nrequest save path: %@ \nrequest headers: \n%@ \nrequest parameters: \n%@ \n==========================================\n", request.url, request.downloadSavePath, request.headers, request.parameters);
        } else {
            NSLog(@"\n============ [XMRequest Info] ============\nrequest url: %@ \nrequest headers: \n%@ \nrequest parameters: \n%@ \n==========================================\n", request.url, request.headers, request.parameters);
        }
    }
    
    // send the request through XMEngine.
    return [[XMEngine sharedEngine] sendRequest:request completionHandler:^(id responseObject, NSError *error) {
        // the completionHandler will be execured in a private concurrent dispatch queue.
        if (error) {
            [self xm_failureWithError:error forRequest:request];
        } else {
            [self xm_successWithResponse:responseObject forRequest:request];
        }
    }];
}

- (void)xm_successWithResponse:(id)responseObject forRequest:(XMRequest *)request {
    
    NSError *processError = nil;
    // custom processing the response data.
    XM_SAFE_BLOCK(self.responseProcessHandler, request, responseObject, &processError);
    if (processError) {
        [self xm_failureWithError:processError forRequest:request];
        return;
    }
    
    if (self.consoleLog) {
        if (request.requestType == kXMRequestDownload) {
            NSLog(@"\n============ [XMResponse Data] ===========\nrequest download url: %@\nresponse data: %@\n==========================================\n", request.url, responseObject);
        } else {
            if (request.responseSerializerType == kXMResponseSerializerRAW) {
                NSLog(@"\n============ [XMResponse Data] ===========\nrequest url: %@ \nresponse data: \n%@\n==========================================\n", request.url, [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            } else {
                NSLog(@"\n============ [XMResponse Data] ===========\nrequest url: %@ \nresponse data: \n%@\n==========================================\n", request.url, responseObject);
            }
        }
    }
    
    if (self.callbackQueue) {
        __weak __typeof(self)weakSelf = self;
        dispatch_async(self.callbackQueue, ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf xm_execureSuccessBlockWithResponse:responseObject forRequest:request];
        });
    } else {
        // execure success block on a private concurrent dispatch queue.
        [self xm_execureSuccessBlockWithResponse:responseObject forRequest:request];
    }
}

- (void)xm_execureSuccessBlockWithResponse:(id)responseObject forRequest:(XMRequest *)request {
    XM_SAFE_BLOCK(request.successBlock, responseObject);
    XM_SAFE_BLOCK(request.finishedBlock, responseObject, nil);
    [request cleanCallbackBlocks];
}

- (void)xm_failureWithError:(NSError *)error forRequest:(XMRequest *)request {
    
    if (self.consoleLog) {
        NSLog(@"\n=========== [XMResponse Error] ===========\nrequest url: %@ \nerror info: \n%@\n==========================================\n", request.url, error);
    }
    
    if (request.retryCount > 0) {
        request.retryCount --;
        // retry current request after 2 seconds.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self xm_sendRequest:request];
        });
        return;
    }
    
    if (self.callbackQueue) {
        __weak __typeof(self)weakSelf = self;
        dispatch_async(self.callbackQueue, ^{
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [strongSelf xm_execureFailureBlockWithError:error forRequest:request];
        });
    } else {
        // execure failure block in a private concurrent dispatch queue.
        [self xm_execureFailureBlockWithError:error forRequest:request];
    }
}

- (void)xm_execureFailureBlockWithError:(NSError *)error forRequest:(XMRequest *)request {
    XM_SAFE_BLOCK(request.failureBlock, error);
    XM_SAFE_BLOCK(request.finishedBlock, nil, error);
    [request cleanCallbackBlocks];
}

#pragma mark - Accessor

- (NSMutableDictionary<NSString *, id> *)generalParameters {
    if (!_generalParameters) {
        _generalParameters = [NSMutableDictionary dictionary];
    }
    return _generalParameters;
}

- (NSMutableDictionary<NSString *, NSString *> *)generalHeaders {
    if (!_generalHeaders) {
        _generalHeaders = [NSMutableDictionary dictionary];
    }
    return _generalHeaders;
}

@end

#pragma mark - XMConfig

@implementation XMConfig
@end
