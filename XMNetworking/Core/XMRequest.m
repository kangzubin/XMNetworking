//
//  XMRequest.m
//  XMNetworking
//
//  Created by Zubin Kang on 12/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMRequest.h"
#import "XMCenter.h"

@interface XMRequest ()

@end

@implementation XMRequest

+ (instancetype)request {
    return [[[self class] alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    // Set default value for XMRequest instance
    _requestType = kXMRequestNormal;
    _httpMethod = kXMHTTPMethodPOST;
    _requestSerializerType = kXMRequestSerializerRAW;
    _responseSerializerType = kXMResponseSerializerJSON;
    _timeoutInterval = 60.0;
    
    _useGeneralServer = YES;
    _useGeneralHeaders = YES;
    _useGeneralParameters = YES;
    
    _retryCount = 0;
    _identifier = 0;
    
    return self;
}

- (void)cleanCallbackBlocks {
    _successBlock = nil;
    _failureBlock = nil;
    _finishedBlock = nil;
    _progressBlock = nil;
}

- (NSMutableArray<XMUploadFormData *> *)uploadFormDatas {
    if (!_uploadFormDatas) {
        _uploadFormDatas = [NSMutableArray array];
    }
    return _uploadFormDatas;
}

- (void)addFormDataWithName:(NSString *)name fileData:(NSData *)fileData {
    XMUploadFormData *formData = [XMUploadFormData formDataWithName:name fileData:fileData];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData {
    XMUploadFormData *formData = [XMUploadFormData formDataWithName:name fileName:fileName mimeType:mimeType fileData:fileData];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileURL:(NSURL *)fileURL {
    XMUploadFormData *formData = [XMUploadFormData formDataWithName:name fileURL:fileURL];
    [self.uploadFormDatas addObject:formData];
}

- (void)addFormDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL {
    XMUploadFormData *formData = [XMUploadFormData formDataWithName:name fileName:fileName mimeType:mimeType fileURL:fileURL];
    [self.uploadFormDatas addObject:formData];
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
}

@end

#pragma mark - XMBatchRequest

@interface XMBatchRequest () {
    dispatch_semaphore_t _lock;
    NSUInteger _finishedCount;
    BOOL _failed;
}

@property (nonatomic, copy) XMBatchSuccessBlock batchSuccessBlock;
@property (nonatomic, copy) XMBatchFailureBlock batchFailureBlock;
@property (nonatomic, copy) XMBatchFinishedBlock batchFinishedBlock;

@end

@implementation XMBatchRequest

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _failed = NO;
    _finishedCount = 0;
    _lock = dispatch_semaphore_create(1);

    _requestArray = [NSMutableArray array];
    _responseArray = [NSMutableArray array];
    
    return self;
}

- (void)onFinishedOneRequest:(XMRequest *)request response:(id)responseObject error:(NSError *)error {
    XMLock();
    NSUInteger index = [_requestArray indexOfObject:request];
    if (responseObject) {
        [_responseArray replaceObjectAtIndex:index withObject:responseObject];
    } else {
        _failed = YES;
        if (error) {
            [_responseArray replaceObjectAtIndex:index withObject:error];
        }
    }
    
    _finishedCount++;
    if (_finishedCount == _requestArray.count) {
        if (!_failed) {
            XM_SAFE_BLOCK(_batchSuccessBlock, _responseArray);
            XM_SAFE_BLOCK(_batchFinishedBlock, _responseArray, nil);
        } else {
            XM_SAFE_BLOCK(_batchFailureBlock, _responseArray);
            XM_SAFE_BLOCK(_batchFinishedBlock, nil, _responseArray);
        }
        [self cleanCallbackBlocks];
    }
    XMUnlock();
}

- (void)cleanCallbackBlocks {
    _batchSuccessBlock = nil;
    _batchFailureBlock = nil;
    _batchFinishedBlock = nil;
}

- (void)cancelWithBlock:(void (^)())cancelBlock {
    if (_requestArray.count > 0) {
        [_requestArray enumerateObjectsUsingBlock:^(XMRequest *obj, NSUInteger idx, __unused BOOL *stop) {
            if (obj.identifier > 0) {
                [XMCenter cancelRequest:obj.identifier];
            }
        }];
    }
    XM_SAFE_BLOCK(cancelBlock);
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
}

@end

#pragma mark - XMChainRequest

@interface XMChainRequest () {
    NSUInteger _chainIndex;
}

@property (nonatomic, strong, readwrite) XMRequest *firstRequest;
@property (nonatomic, strong, readwrite) XMRequest *nextRequest;

@property (nonatomic, strong) NSMutableArray<XMChainNextBlock> *nextBlockArray;
@property (nonatomic, strong) NSMutableArray<id> *responseArray;

@property (nonatomic, copy) XMBatchSuccessBlock chainSuccessBlock;
@property (nonatomic, copy) XMBatchFailureBlock chainFailureBlock;
@property (nonatomic, copy) XMBatchFinishedBlock chainFinishedBlock;

@end

@implementation XMChainRequest : NSObject

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _chainIndex = 0;
    _responseArray = [NSMutableArray array];
    _nextBlockArray = [NSMutableArray array];
    
    return self;
}

- (XMChainRequest *)onFirst:(XMRequestConfigBlock)firstBlock {
    NSAssert(firstBlock != nil, @"The first block for chain requests can't be nil.");
    NSAssert(_nextBlockArray.count == 0, @"The `onFirst:` method must called befault `onNext:` method");
    _firstRequest = [XMRequest request];
    firstBlock(_firstRequest);
    [_responseArray addObject:[NSNull null]];
    return self;
}

- (XMChainRequest *)onNext:(XMChainNextBlock)nextBlock {
    NSAssert(nextBlock != nil, @"The next block for chain requests can't be nil.");
    [_nextBlockArray addObject:nextBlock];
    [_responseArray addObject:[NSNull null]];
    return self;
}

- (void)onFinishedOneRequest:(XMRequest *)request response:(id)responseObject error:(NSError *)error {
    if (responseObject) {
        [_responseArray replaceObjectAtIndex:_chainIndex withObject:responseObject];
        if (_chainIndex < _nextBlockArray.count) {
            _nextRequest = [XMRequest request];
            XMChainNextBlock nextBlock = _nextBlockArray[_chainIndex];
            BOOL startNext = YES;
            nextBlock(_nextRequest, responseObject, &startNext);
            if (!startNext) {
                XM_SAFE_BLOCK(_chainFailureBlock, _responseArray);
                XM_SAFE_BLOCK(_chainFinishedBlock, nil, _responseArray);
                [self cleanCallbackBlocks];
            }
        } else {
            XM_SAFE_BLOCK(_chainSuccessBlock, _responseArray);
            XM_SAFE_BLOCK(_chainFinishedBlock, nil, _responseArray);
            [self cleanCallbackBlocks];
        }
    } else {
        if (error) {
            [_responseArray replaceObjectAtIndex:_chainIndex withObject:error];
        }
        XM_SAFE_BLOCK(_chainFailureBlock, _responseArray);
        XM_SAFE_BLOCK(_chainFinishedBlock, nil, _responseArray);
        [self cleanCallbackBlocks];
    }
    _chainIndex++;
}

- (void)cleanCallbackBlocks {
    _firstRequest = nil;
    _nextRequest = nil;
    _chainSuccessBlock = nil;
    _chainFailureBlock = nil;
    _chainFinishedBlock = nil;
    [_nextBlockArray removeAllObjects];
}

- (void)cancelWithBlock:(void (^)())cancelBlock {
    if (_firstRequest && !_nextRequest) {
        [XMCenter cancelRequest:_firstRequest.identifier];
    } else if (_nextRequest) {
        [XMCenter cancelRequest:_nextRequest.identifier];
    }
    XM_SAFE_BLOCK(cancelBlock);
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
}

@end

#pragma mark - XMUploadFormData

@implementation XMUploadFormData

+ (instancetype)formDataWithName:(NSString *)name fileData:(NSData *)fileData {
    XMUploadFormData *formData = [[XMUploadFormData alloc] init];
    formData.name = name;
    formData.fileData = fileData;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileData:(NSData *)fileData {
    XMUploadFormData *formData = [[XMUploadFormData alloc] init];
    formData.name = name;
    formData.fileName = fileName;
    formData.mimeType = mimeType;
    formData.fileData = fileData;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileURL:(NSURL *)fileURL {
    XMUploadFormData *formData = [[XMUploadFormData alloc] init];
    formData.name = name;
    formData.fileURL = fileURL;
    return formData;
}

+ (instancetype)formDataWithName:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType fileURL:(NSURL *)fileURL {
    XMUploadFormData *formData = [[XMUploadFormData alloc] init];
    formData.name = name;
    formData.fileName = fileName;
    formData.mimeType = mimeType;
    formData.fileURL = fileURL;
    return formData;
}

@end
