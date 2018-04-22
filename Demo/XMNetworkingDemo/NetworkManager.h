//
//  NetworkManager.h
//  XMNetworkingDemo
//
//  Created by Zubin Kang on 2018/4/20.
//  Copyright © 2018 XMNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMNetworking.h"

/**
 XMNetworking 使用配置示例
 */

typedef NS_ENUM(NSInteger, XMNetworkErrorCode) {
    kXMSuccessCode = 0,      //!< 接口请求成功
    kXMErrorCode = 1,        //!< 接口请求失败
    kXMUnknownCode = -1,     //!< 未知错误
};

// 根据业务员场景扩展 XMRequest
@interface XMRequest (Utils)
@property (nonatomic, copy) NSString *version; //!< 接口版本号
@end

#pragma mark -

@interface NetworkManager : NSObject

/**
 初始化网络配置
 */
+ (void)setup;

@end
