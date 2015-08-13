//
//  FLYFriendCell.h
//  Fly
//
//  Created by Kevin Yang on 8/1/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLYUser.h"

@interface FLYFriendCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *fullnameLabel;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIImageView *emoticonImageView;
@property (strong, nonatomic) FLYUser *flyUser;
@end
