//
//  XMCache.m
//  XMNetworkingDemo
//
//  Created by 一只皮卡丘 on 2018/7/24.
//  Copyright © 2018年 XMNetworking. All rights reserved.
//

#import "XMCache.h"
#import <YYCache.h>

@implementation XMCache
{
    YYCache  *_cache;
}

+ (instancetype)cache
{
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[XMCache alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cache = [YYCache cacheWithName:@"XMNetworkingCache"];
    }
    return self;
}

- (void)clearAllCache
{
    [_cache removeAllObjects];
}

- (__nullable id)getRequestCacheByUrl:(NSString *)url
{
    return [_cache objectForKey:url];
}

- (void)cacheDataInMemory:(id)data withKey:(NSString *)key
{
    [_cache.memoryCache setObject:data forKey:key];
}

- (void)cacheDataInDisk:(id)data withKey:(NSString *)key
{
    [_cache.diskCache setObject:data forKey:key];
}

- (void)cacheDataInMemoryAndDisk:(id)data withKey:(NSString *)key
{
    [_cache setObject:data forKey:key];
}

+ (void)clearAllCache
{
    [[XMCache cache] clearAllCache];
}

+ (__nullable id)getRequestCacheByUrl:(NSString *)url
{
    return [[XMCache cache] getRequestCacheByUrl:url];
}

+ (void)cacheDataInMemory:(id)data withKey:(NSString *)key
{
    return [[XMCache cache] cacheDataInMemory:data withKey:key];
}

+ (void)cacheDataInDisk:(id)data withKey:(NSString *)key
{
    return [[XMCache cache] cacheDataInDisk:data withKey:key];
}

+ (void)cacheDataInMemoryAndDisk:(id)data withKey:(NSString *)key
{
    return [[XMCache cache] cacheDataInMemoryAndDisk:data withKey:key];
}

@end
