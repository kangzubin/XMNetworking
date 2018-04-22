//
//  TipSetItemModel.h
//  XMNetworkingDemo
//
//  Created by Zubin Kang on 2018/4/20.
//  Copyright © 2018 XMNetworking. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TipSetItemModel : NSObject

@property (nonatomic, copy) NSString *fid;
@property (nonatomic, copy) NSString *auther;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *postdate;
@property (nonatomic, assign) NSInteger platform;
@property (nonatomic, copy, readonly) NSString *platformString;

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

@end
