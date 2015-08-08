//
//  FLYFriendCell.m
//  Fly
//
//  Created by Kevin Yang on 8/1/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYFriendCell.h"
#import "FLYAppDelegate.h"

@implementation FLYFriendCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)addFriendButton:(UIButton *)sender {
    NSLog(@"ADD FRIEND");
    sender.selected = !sender.selected;
    [self addFriendFirebase:self.flyUser.uid];
}

- (void)addFriendFirebase:(NSString *)friendUID{
    Firebase *flyRef = [FLYAppDelegate flyRef];
    Firebase *meToFriendRef = [[flyRef childByAppendingPath:@"friendship"] childByAppendingPath:flyRef.authData.uid];
    Firebase *friendToMeRef = [[flyRef childByAppendingPath:@"friendship"] childByAppendingPath:friendUID];
    [friendToMeRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *meToFriendFriendship = @{friendUID:@NO};
        if (![snapshot.value isEqual:[NSNull null]]) {   //to protect against friend's missing friendship branch
            if ([snapshot.value objectForKey:flyRef.authData.uid]) {  //if mutual friends, set true to both friendships
                meToFriendFriendship = @{friendUID: @YES};
                NSDictionary *friendToMeFriendship = @{flyRef.authData.uid: @YES};
                [friendToMeRef updateChildValues:friendToMeFriendship];
            }
        }
        [meToFriendRef updateChildValues:meToFriendFriendship];
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}



@end
