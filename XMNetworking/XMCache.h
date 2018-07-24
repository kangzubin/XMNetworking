//
//  XMCache.h
//  XMNetworkingDemo
//
//  Created by 一只皮卡丘 on 2018/7/24.
//  Copyright © 2018年 XMNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface XMCache : NSObject

+ (instancetype)cache;

+ (void)clearAllCache;

+ (__nullable id)getRequestCacheByUrl:(NSString *)url;

+ (void)cacheDataInMemory:(id)data withKey:(NSString *)key;

+ (void)cacheDataInDisk:(id)data withKey:(NSString *)key;

+ (void)cacheDataInMemoryAndDisk:(id)data withKey:(NSString *)key;

- (void)clearAllCache;

- (__nullable id)getRequestCacheByUrl:(NSString *)url;

- (void)cacheDataInMemory:(id)data withKey:(NSString *)key;

- (void)cacheDataInDisk:(id)data withKey:(NSString *)key;

- (void)cacheDataInMemoryAndDisk:(id)data withKey:(NSString *)key;

@end
NS_ASSUME_NONNULL_END
