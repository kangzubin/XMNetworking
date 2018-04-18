//
//  XMRequest.m
//  XMNetworking
//
//  Created by Zubin Kang on 12/12/2016.
//  Copyright © 2016 XMNetworking. All rights reserved.
//

#import "XMRequest.h"

//#define XMMEMORYLOG

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
    
#ifdef XMMEMORYLOG
    NSLog(@"%@: %s", self, __FUNCTION__);
#endif
    
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

#ifdef XMMEMORYLOG
- (void)dealloc {
    NSLog(@"%@: %s", self, __FUNCTION__);
}
#endif

@end

#pragma mark - XMBatchRequest

@interface XMBatchRequest () {
    dispatch_semaphore_t _lock;
    NSUInteger _finishedCount;
    BOOL _failed;
}

@property (nonatomic, copy) XMBCSuccessBlock batchSuccessBlock;
@property (nonatomic, copy) XMBCFailureBlock batchFailureBlock;
@property (nonatomic, copy) XMBCFinishedBlock batchFinishedBlock;

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

#ifdef XMMEMORYLOG
    NSLog(@"%@: %s", self, __FUNCTION__);
#endif
    
    return self;
}

- (BOOL)onFinishedOneRequest:(XMRequest *)request response:(id)responseObject error:(NSError *)error {
    BOOL isFinished = NO;
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
        isFinished = YES;
    }
    XMUnlock();
    return isFinished;
}

- (void)cleanCallbackBlocks {
    _batchSuccessBlock = nil;
    _batchFailureBlock = nil;
    _batchFinishedBlock = nil;
}

#ifdef XMMEMORYLOG
- (void)dealloc {
    NSLog(@"%@: %s", self, __FUNCTION__);
}
#endif

@end

#pragma mark - XMChainRequest

@interface XMChainRequest () {
    NSUInteger _chainIndex;
}

@property (nonatomic, strong, readwrite) XMRequest *runningRequest;

@property (nonatomic, strong) NSMutableArray<XMBCNextBlock> *nextBlockArray;
@property (nonatomic, strong) NSMutableArray *responseArray;

@property (nonatomic, copy) XMBCSuccessBlock chainSuccessBlock;
@property (nonatomic, copy) XMBCFailureBlock chainFailureBlock;
@property (nonatomic, copy) XMBCFinishedBlock chainFinishedBlock;

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
    
#ifdef XMMEMORYLOG
    NSLog(@"%@: %s", self, __FUNCTION__);
#endif
    
    return self;
}

- (XMChainRequest *)onFirst:(XMRequestConfigBlock)firstBlock {
    NSAssert(firstBlock != nil, @"The first block for chain requests can't be nil.");
    NSAssert(_nextBlockArray.count == 0, @"The `-onFirst:` method must called befault `-onNext:` method");
    _runningRequest = [XMRequest request];
    firstBlock(_runningRequest);
    [_responseArray addObject:[NSNull null]];
    return self;
}

- (XMChainRequest *)onNext:(XMBCNextBlock)nextBlock {
    NSAssert(nextBlock != nil, @"The next block for chain requests can't be nil.");
    [_nextBlockArray addObject:nextBlock];
    [_responseArray addObject:[NSNull null]];
    return self;
}

- (BOOL)onFinishedOneRequest:(XMRequest *)request response:(id)responseObject error:(NSError *)error {
    BOOL isFinished = NO;
    if (responseObject) {
        [_responseArray replaceObjectAtIndex:_chainIndex withObject:responseObject];
        if (_chainIndex < _nextBlockArray.count) {
            _runningRequest = [XMRequest request];
            XMBCNextBlock nextBlock = _nextBlockArray[_chainIndex];
            BOOL isSent = YES;
            nextBlock(_runningRequest, responseObject, &isSent);
            if (!isSent) {
                XM_SAFE_BLOCK(_chainFailureBlock, _responseArray);
                XM_SAFE_BLOCK(_chainFinishedBlock, nil, _responseArray);
                [self cleanCallbackBlocks];
                isFinished = YES;
            }
        } else {
            XM_SAFE_BLOCK(_chainSuccessBlock, _responseArray);
            XM_SAFE_BLOCK(_chainFinishedBlock, _responseArray, nil);
            [self cleanCallbackBlocks];
            isFinished = YES;
        }
    } else {
        if (error) {
            [_responseArray replaceObjectAtIndex:_chainIndex withObject:error];
        }
        XM_SAFE_BLOCK(_chainFailureBlock, _responseArray);
        XM_SAFE_BLOCK(_chainFinishedBlock, nil, _responseArray);
        [self cleanCallbackBlocks];
        isFinished = YES;
    }
    _chainIndex++;
    return isFinished;
}

- (void)cleanCallbackBlocks {
    _runningRequest = nil;
    _chainSuccessBlock = nil;
    _chainFailureBlock = nil;
    _chainFinishedBlock = nil;
    [_nextBlockArray removeAllObjects];
}

#ifdef XMMEMORYLOG
- (void)dealloc {
    NSLog(@"%@: %s", self, __FUNCTION__);
}
#endif

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
