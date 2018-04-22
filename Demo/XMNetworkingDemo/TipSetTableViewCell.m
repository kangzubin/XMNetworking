//
//  TipSetTableViewCell.m
//  XMNetworkingDemo
//
//  Created by Zubin Kang on 2018/4/20.
//  Copyright © 2018 XMNetworking. All rights reserved.
//

#import "TipSetTableViewCell.h"
#import "TipSetItemModel.h"

@implementation TipSetTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.numberOfLines = 2;
        self.textLabel.textColor = [UIColor darkGrayColor];
        self.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    return self;
}

- (void)updateUIWithModel:(TipSetItemModel *)model {
    self.textLabel.text = model.title;
    self.detailTextLabel.text = [NSString stringWithFormat:@"%@ @%@ · %@", model.postdate, model.auther, model.platformString];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)cellHeight {
    return 80.0f;
}

+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self.class);
}

@end
