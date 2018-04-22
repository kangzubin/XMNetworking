//
//  TipSetItemModel.m
//  XMNetworkingDemo
//
//  Created by Zubin Kang on 2018/4/20.
//  Copyright © 2018 XMNetworking. All rights reserved.
//

#import "TipSetItemModel.h"

@implementation TipSetItemModel

+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary {
    if ([dictionary isKindOfClass:[NSDictionary class]] && [[dictionary allKeys] count] > 0) {
        TipSetItemModel *model = [[TipSetItemModel alloc] init];
        model.fid = [self xm_asssignEmptyString:dictionary[@"fid"]];
        model.auther = [self xm_asssignEmptyString:dictionary[@"auther"]];
        model.title = [self xm_asssignEmptyString:dictionary[@"title"]];
        model.url = [self xm_asssignEmptyString:dictionary[@"url"]];
        model.postdate = [self xm_asssignEmptyString:dictionary[@"postdate"]];
        model.platform = [dictionary[@"platform"] integerValue];
        return model;
    }
    return nil;
}

+ (NSString *)xm_asssignEmptyString:(NSString *)string {
    if (string == nil) {
        return @"";
    }
    
    if ((NSNull *)string == [NSNull null]) {
        return @"";
    }
    
    if ([string isKindOfClass:[NSNumber class]]) {
        return [NSString stringWithFormat:@"%@", string];;
    }
    
    if (![string isKindOfClass:[NSString class]]) {
        return @"";
    }
    
    if ([string isEqualToString:@"<null>"]) {
        return @"";
    }
    if ([string isEqualToString:@"(null)"]) {
        return @"";
    }
    if ([string isEqualToString:@"null"]) {
        return @"";
    }
    
    return string;
}

- (NSString *)platformString {
    switch (self.platform) {
        case 0:
            return @"微博";
        case 1:
            return @"公众号";
        case 2:
            return @"GitHub";
        case 3:
            return @"Meidum";
        default:
            return @"未知";
    }
}

@end
