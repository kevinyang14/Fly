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

- (IBAction)addFriendButton:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        NSLog(@"ADD FRIEND");
        [self addFriendFirebase:self.flyUser.uid];
    }else{
        NSLog(@"REMOVE FRIEND");
        [self removeFriendFirebase:self.flyUser.uid];
    }
}


//BUG: whenever I add, remove. Remove doesn't work
- (void)addFriendFirebase:(NSString *)friendUID{
    Firebase *flyRef = [FLYAppDelegate flyRef];
    Firebase *myFriendsRef = [[flyRef childByAppendingPath:@"friendship"] childByAppendingPath:[FLYAppDelegate userUID]];	//my friendship branch
    Firebase *friendFriendsRef = [[flyRef childByAppendingPath:@"friendship"] childByAppendingPath:friendUID];			//friend's friendship branch
    
    //check if friend sent a friendRequest
    [friendFriendsRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *meToFriendFriendship = @{friendUID:@NO};
        if (![snapshot.value isEqual:[NSNull null]]) {                              //protect against an empty friendship branch
            if ([snapshot.value objectForKey:flyRef.authData.uid]) {                //if friendRequest, set both friendships to true
                meToFriendFriendship = @{friendUID: @YES};
                NSDictionary *friendToMeFriendship = @{flyRef.authData.uid: @YES};	//add me to friend's friends
                [friendFriendsRef updateChildValues:friendToMeFriendship];
            }
        }
        [myFriendsRef updateChildValues:meToFriendFriendship];                      //add friend to my friends
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

-(void)removeFriendFirebase:(NSString *)friendUID{
    NSString *myUID = [FLYAppDelegate userUID];
    Firebase *friendshipRef = [[FLYAppDelegate flyRef] childByAppendingPath:@"friendship"];
    Firebase *removeFromMyRef = [[friendshipRef childByAppendingPath:myUID] childByAppendingPath:friendUID]; //my friendship branch
    Firebase *removeFromFriendRef = [friendshipRef childByAppendingPath:friendUID];	//friend's friendship branch
    
    NSLog(@"friendUID: %@", friendUID);
    //remove friend from my branch
    [removeFromMyRef removeValueWithCompletionBlock:^(NSError *error, Firebase *ref) {
        if (error) {
            NSLog(@"error");
        }
        NSLog(@"removed");
    }];
    
    //falsify me from friend branch
    NSDictionary *friendToMeFriendship = @{myUID:@NO};
    [removeFromFriendRef updateChildValues:friendToMeFriendship withCompletionBlock:^(NSError *error, Firebase *ref) {
        if (error) {
            NSLog(@"error");
        }
        NSLog(@"falsified");
    }];
}


@end
