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

static OSStatus XMExtractIdentityAndTrustFromPKCS12(CFDataRef inPKCS12Data, CFStringRef keyPassword, SecIdentityRef *outIdentity, SecTrustRef *outTrust) {
    OSStatus securityError = errSecSuccess;
    
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { keyPassword };
    CFDictionaryRef optionsDictionary = NULL;
    
    /* Create a dictionary containing the passphrase if one was specified. Otherwise, create an empty dictionary. */
    optionsDictionary = CFDictionaryCreate(NULL, keys, values, (keyPassword ? 1 : 0), NULL, NULL);
    
    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import(inPKCS12Data, optionsDictionary, &items);
    
    if (securityError == 0) {
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex(items, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(myIdentityAndTrust, kSecImportItemIdentity);
        CFRetain(tempIdentity);
        *outIdentity = (SecIdentityRef)tempIdentity;
        
        const void *tempTrust = NULL;
        tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);
        CFRetain(tempTrust);
        *outTrust = (SecTrustRef)tempTrust;
    }
    
    if (optionsDictionary) {
        CFRelease(optionsDictionary);
    }
    
    if (items) {
        CFRelease(items);
    }
    
    return securityError;
}

#pragma mark - XMRequest Binding

@implementation NSObject (BindingXMRequest)

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

@interface XMEngine () {
    dispatch_semaphore_t _lock;
}

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) AFHTTPSessionManager *securitySessionManager;

@property (nonatomic, strong) AFHTTPRequestSerializer *afHTTPRequestSerializer;
@property (nonatomic, strong) AFJSONRequestSerializer *afJSONRequestSerializer;
@property (nonatomic, strong) AFPropertyListRequestSerializer *afPListRequestSerializer;

@property (nonatomic, strong) AFHTTPResponseSerializer *afHTTPResponseSerializer;
@property (nonatomic, strong) AFJSONResponseSerializer *afJSONResponseSerializer;
@property (nonatomic, strong) AFXMLParserResponseSerializer *afXMLResponseSerializer;
@property (nonatomic, strong) AFPropertyListResponseSerializer *afPListResponseSerializer;

@property (nonatomic, strong) NSMutableArray *sslPinningHosts;

@end

@implementation XMEngine

+ (instancetype)engine {
    return [[[self class] alloc] init];
}

+ (instancetype)sharedEngine {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self engine];
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
    if (_securitySessionManager) {
        [_securitySessionManager invalidateSessionCancelingTasks:YES];
    }
}

#pragma mark - Public Methods

- (void)sendRequest:(XMRequest *)request completionHandler:(XMCompletionHandler)completionHandler {
    if (request.requestType == kXMRequestNormal) {
        [self xm_dataTaskWithRequest:request completionHandler:completionHandler];
    } else if (request.requestType == kXMRequestUpload) {
        [self xm_uploadTaskWithRequest:request completionHandler:completionHandler];
    } else if (request.requestType == kXMRequestDownload) {
        [self xm_downloadTaskWithRequest:request completionHandler:completionHandler];
    } else {
        NSAssert(NO, @"Unknown request type.");
    }
}

- (XMRequest *)cancelRequestByIdentifier:(NSString *)identifier {
    if (identifier.length == 0) return nil;
    
    XMLock();
    NSArray *tasks = nil;
    if ([identifier hasPrefix:@"+"]) {
        tasks = self.sessionManager.tasks;
    } else if ([identifier hasPrefix:@"-"]) {
        tasks = self.securitySessionManager.tasks;
    }
    __block XMRequest *request = nil;
    if (tasks.count > 0) {
        [tasks enumerateObjectsUsingBlock:^(NSURLSessionTask *task, NSUInteger idx, BOOL *stop) {
            if ([task.bindedRequest.identifier isEqualToString:identifier]) {
                request = task.bindedRequest;
                [task cancel];
                *stop = YES;
            }
        }];
    }
    XMUnlock();
    return request;
}

- (XMRequest *)getRequestByIdentifier:(NSString *)identifier {
    if (identifier.length == 0) return nil;
    
    XMLock();
    NSArray *tasks = nil;
    if ([identifier hasPrefix:@"+"]) {
        tasks = self.sessionManager.tasks;
    } else if ([identifier hasPrefix:@"-"]) {
        tasks = self.securitySessionManager.tasks;
    }
    __block XMRequest *request = nil;
    [tasks enumerateObjectsUsingBlock:^(NSURLSessionTask *task, NSUInteger idx, BOOL *stop) {
        if ([task.bindedRequest.identifier isEqualToString:identifier]) {
            request = task.bindedRequest;
            *stop = YES;
        }
    }];
    XMUnlock();
    return request;
}

- (NSInteger)reachabilityStatus {
    return [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
}

- (void)addSSLPinningURL:(NSString *)url {
    NSParameterAssert(url);
    
    if ([url hasPrefix:@"https"]) {
        NSString *rootDomainName = [self xm_rootDomainNameFromURL:url];
        if (rootDomainName && ![self.sslPinningHosts containsObject:rootDomainName]) {
            [self.sslPinningHosts addObject:rootDomainName];
        }
    }
}

- (void)addSSLPinningCert:(NSData *)cert {
    NSParameterAssert(cert);
    
    NSMutableSet *certSet;
    if (self.securitySessionManager.securityPolicy.pinnedCertificates.count > 0) {
        certSet = [NSMutableSet setWithSet:self.securitySessionManager.securityPolicy.pinnedCertificates];
    } else {
        certSet = [NSMutableSet set];
    }
    [certSet addObject:cert];
    [self.securitySessionManager.securityPolicy setPinnedCertificates:certSet];}

- (void)addTwowayAuthenticationPKCS12:(NSData *)p12 keyPassword:(NSString *)password {
    NSParameterAssert(p12);
    NSParameterAssert(password);
    
    __weak __typeof(self)weakSelf = self;
    [self.securitySessionManager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable credential) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
            // Server Trust (SSL Pinning)
            if ([strongSelf.securitySessionManager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                if (*credential) {
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]) {
            // Client Certificate (Two-way Authentication)
            SecIdentityRef identity = NULL;
            SecTrustRef trust = NULL;
            
            if (XMExtractIdentityAndTrustFromPKCS12((__bridge CFDataRef)p12, (__bridge CFStringRef)password, &identity, &trust) == 0) {
                SecCertificateRef certificate = NULL;
                SecIdentityCopyCertificate(identity, &certificate);
                
                const void *certs[] = { certificate };
                CFArrayRef certArray = CFArrayCreate(kCFAllocatorDefault, certs, 1, NULL);
                *credential = [NSURLCredential credentialWithIdentity:identity certificates:(__bridge NSArray *)certArray persistence:NSURLCredentialPersistencePermanent];
                if (*credential) {
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
                
                if (certificate) {
                    CFRelease(certificate);
                }
                if (certArray) {
                    CFRelease(certArray);
                }
            }
            
            if (identity) {
                CFRelease(identity);
            }
            if (trust) {
                CFRelease(trust);
            }
        } else {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        }
        
        return disposition;
    }];
}

#pragma mark - Private Methods

- (void)xm_dataTaskWithRequest:(XMRequest *)request
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
    
    AFHTTPSessionManager *sessionManager = [self xm_getSessionManager:request];
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
        return;
    }
    
    [self xm_processURLRequest:urlRequest byXMRequest:request];
    
    NSURLSessionDataTask *dataTask = nil;
    __weak __typeof(self)weakSelf = self;
    dataTask = [sessionManager dataTaskWithRequest:urlRequest
                                      completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf xm_processResponse:response
                                object:responseObject
                                 error:error
                               request:request
                     completionHandler:completionHandler];
    }];
    
    [self xm_setIdentifierForReqeust:request taskIdentifier:dataTask.taskIdentifier sessionManager:sessionManager];
    [dataTask bindingRequest:request];
    [dataTask resume];
}

- (void)xm_uploadTaskWithRequest:(XMRequest *)request
               completionHandler:(XMCompletionHandler)completionHandler {
    
    AFHTTPSessionManager *sessionManager = [self xm_getSessionManager:request];
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
        return;
    }
    
    [self xm_processURLRequest:urlRequest byXMRequest:request];
    
    NSURLSessionUploadTask *uploadTask = nil;
    __weak __typeof(self)weakSelf = self;
    uploadTask = [sessionManager uploadTaskWithStreamedRequest:urlRequest
                                                           progress:request.progressBlock
                                                  completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf xm_processResponse:response
                                object:responseObject
                                 error:error
                               request:request
                     completionHandler:completionHandler];
    }];
    
    [self xm_setIdentifierForReqeust:request taskIdentifier:uploadTask.taskIdentifier sessionManager:sessionManager];
    [uploadTask bindingRequest:request];
    [uploadTask resume];
}

- (void)xm_downloadTaskWithRequest:(XMRequest *)request
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
    AFHTTPSessionManager *sessionManager = [self xm_getSessionManager:request];
    downloadTask = [sessionManager downloadTaskWithRequest:urlRequest
                                                       progress:request.progressBlock
                                                    destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                                        return downloadFileSavePath;
                                                    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                        if (completionHandler) {
                                                            completionHandler(filePath, error);
                                                        }
                                                    }];
    
    [self xm_setIdentifierForReqeust:request taskIdentifier:downloadTask.taskIdentifier sessionManager:sessionManager];
    [downloadTask bindingRequest:request];
    [downloadTask resume];
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

- (void)xm_setIdentifierForReqeust:(XMRequest *)request
                    taskIdentifier:(NSUInteger)taskIdentifier
                    sessionManager:(AFHTTPSessionManager *)sessionManager {
    NSString *identifier = nil;
    if ([sessionManager isEqual:self.sessionManager]) {
        identifier = [NSString stringWithFormat:@"+%lu", (unsigned long)taskIdentifier];
    } else if ([sessionManager isEqual:self.securitySessionManager]) {
        identifier = [NSString stringWithFormat:@"-%lu", (unsigned long)taskIdentifier];
    }
    [request setValue:identifier forKey:@"_identifier"];
}

- (NSString *)xm_rootDomainNameFromURL:(NSString *)urlString {
    NSString *host = [[NSURL URLWithString:urlString] host];
    // Separate the host into its constituent components, e.g. [@"secure", @"twitter", @"com"]
    NSArray * hostComponents = [host componentsSeparatedByString:@"."];
    if ([hostComponents count] >= 2) {
        // Create a string out of the last two components in the host name, e.g. @"twitter" and @"com"
        host = [NSString stringWithFormat:@"%@.%@", [hostComponents objectAtIndex:(hostComponents.count - 2)], [hostComponents objectAtIndex:(hostComponents.count - 1)]];
    }
    return host;
}

- (BOOL)xm_shouldSSLPinningWithURL:(NSString *)urlString {
    if (urlString && [urlString hasPrefix:@"https"]) {
        NSString *rootDomainName = [self xm_rootDomainNameFromURL:urlString];
        if ([self.sslPinningHosts containsObject:rootDomainName]) {
            return YES;
        }
    }
    return NO;
}

- (AFHTTPSessionManager *)xm_getSessionManager:(XMRequest *)request {
    if ([self xm_shouldSSLPinningWithURL:request.url]) {
        return self.securitySessionManager;
    } else {
        return self.sessionManager;
    }
}

- (AFHTTPRequestSerializer *)xm_getRequestSerializer:(XMRequest *)request {
    if (request.requestSerializerType == kXMRequestSerializerRAW) {
        return self.afHTTPRequestSerializer;
    } else if(request.requestSerializerType == kXMRequestSerializerJSON) {
        return self.afJSONRequestSerializer;
    } else if (request.requestSerializerType == kXMRequestSerializerPlist) {
        return self.afPListRequestSerializer;
    } else {
        NSAssert(NO, @"Unknown request serializer type.");
        return nil;
    }
}

- (AFHTTPResponseSerializer *)xm_getResponseSerializer:(XMRequest *)request {
    if (request.responseSerializerType == kXMResponseSerializerRAW) {
        return self.afHTTPResponseSerializer;
    } else if (request.responseSerializerType == kXMResponseSerializerJSON) {
        return self.afJSONResponseSerializer;
    } else if (request.responseSerializerType == kXMResponseSerializerPlist) {
        return self.afPListResponseSerializer;
    } else if (request.responseSerializerType == kXMResponseSerializerXML) {
        return self.afXMLResponseSerializer;
    } else {
        NSAssert(NO, @"Unknown response serializer type.");
        return nil;
    }
}

#pragma mark - Accessor

- (AFHTTPSessionManager *)sessionManager {
    if (!_sessionManager) {
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.requestSerializer = self.afHTTPRequestSerializer;
        _sessionManager.responseSerializer = self.afHTTPResponseSerializer;
        _sessionManager.operationQueue.maxConcurrentOperationCount = 5;
        _sessionManager.completionQueue = xm_request_completion_callback_queue();
    }
    return _sessionManager;
}

- (AFHTTPSessionManager *)securitySessionManager {
    if (!_securitySessionManager) {
        _securitySessionManager = [AFHTTPSessionManager manager];
        _securitySessionManager.requestSerializer = self.afHTTPRequestSerializer;
        _securitySessionManager.responseSerializer = self.afHTTPResponseSerializer;
        _securitySessionManager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        _securitySessionManager.operationQueue.maxConcurrentOperationCount = 5;
        _securitySessionManager.completionQueue = xm_request_completion_callback_queue();
    }
    return _securitySessionManager;
}

- (AFHTTPRequestSerializer *)afHTTPRequestSerializer {
    if (!_afHTTPRequestSerializer) {
        _afHTTPRequestSerializer = [AFHTTPRequestSerializer serializer];
        
    }
    return _afHTTPRequestSerializer;
}

- (AFJSONRequestSerializer *)afJSONRequestSerializer {
    if (!_afJSONRequestSerializer) {
        _afJSONRequestSerializer = [AFJSONRequestSerializer serializer];
        
    }
    return _afJSONRequestSerializer;
}

- (AFPropertyListRequestSerializer *)afPListRequestSerializer {
    if (!_afPListRequestSerializer) {
        _afPListRequestSerializer = [AFPropertyListRequestSerializer serializer];
    }
    return _afPListRequestSerializer;
}

- (AFHTTPResponseSerializer *)afHTTPResponseSerializer {
    if (!_afHTTPResponseSerializer) {
        _afHTTPResponseSerializer = [AFHTTPResponseSerializer serializer];
    }
    return _afHTTPResponseSerializer;
}

- (AFJSONResponseSerializer *)afJSONResponseSerializer {
    if (!_afJSONResponseSerializer) {
        _afJSONResponseSerializer = [AFJSONResponseSerializer serializer];
        // Append more other commonly-used types to the JSON responses accepted MIME types.
        //_afJSONResponseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", nil];
    }
    return _afJSONResponseSerializer;
}

- (AFXMLParserResponseSerializer *)afXMLResponseSerializer {
    if (!_afXMLResponseSerializer) {
        _afXMLResponseSerializer = [AFXMLParserResponseSerializer serializer];
    }
    return _afXMLResponseSerializer;
}

- (AFPropertyListResponseSerializer *)afPListResponseSerializer {
    if (!_afPListResponseSerializer) {
        _afPListResponseSerializer = [AFPropertyListResponseSerializer serializer];
    }
    return _afPListResponseSerializer;
}

- (NSMutableArray *)sslPinningHosts {
    if (!_sslPinningHosts) {
        _sslPinningHosts = [NSMutableArray array];
    }
    return _sslPinningHosts;
}

@end
