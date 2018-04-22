//
//  TipSetTableViewCell.h
//  XMNetworkingDemo
//
//  Created by Zubin Kang on 2018/4/20.
//  Copyright © 2018 XMNetworking. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TipSetItemModel;

@interface TipSetTableViewCell : UITableViewCell

- (void)updateUIWithModel:(TipSetItemModel *)model;

+ (CGFloat)cellHeight;
+ (NSString *)reuseIdentifier;

@end
