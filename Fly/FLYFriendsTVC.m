//
//  FLYFriendsTVC.m
//  Fly
//
//  Created by Kevin Yang on 8/1/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYFriendsTVC.h"
#import "FLYAppDelegate.h"
#import "FLYUser.h"
#import "FLYFriendCell.h"
#import "SVProgressHUD.h"
#import <QuartzCore/QuartzCore.h>


@interface FLYFriendsTVC ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableDictionary *allUsersDictionary;
@property (strong, nonatomic) NSMutableDictionary *friendsDictionary;
@property (strong, nonatomic) NSMutableArray *allUsersArray;
@end

@implementation FLYFriendsTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupFirebase];
    [self setupUI];
}

- (void)setupUI{
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.allowsSelection = NO;
    [self.navigationController.navigationBar setTitleTextAttributes:
      [NSDictionary dictionaryWithObjectsAndKeys:
      [UIFont fontWithName:@"HelveticaNeue-Light" size:25.0],
       NSFontAttributeName, nil]];
}

#pragma mark Firebase Methods

- (void) setupFirebase{
    [SVProgressHUD show];
    Firebase *usersRef = [[FLYAppDelegate flyRef] childByAppendingPath:@"users"];
    Firebase *friendsRef = [[FLYAppDelegate flyRef] childByAppendingPath:@"friendship"];
    Firebase *myFriendsRef = [friendsRef childByAppendingPath:[FLYAppDelegate userUID]];
    
    //fetch all fly users
    [usersRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        [self storeAllFlyUsersWithDictionary:snapshot.value];
        //fetch all my friends
        [myFriendsRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            self.friendsDictionary = snapshot.value;
            [self.tableView reloadData];
            [SVProgressHUD dismiss];
        }];
    }];
}

- (void) storeAllFlyUsersWithDictionary:(NSMutableDictionary *)allUsersDictionary{
    for(NSString *uidKey in allUsersDictionary){
        if (![uidKey isEqualToString:[FLYAppDelegate userUID]]) {
            NSMutableDictionary *userDictionary = [allUsersDictionary objectForKey:uidKey];
            FLYUser *currentUser = [[FLYUser alloc] initWithUID:uidKey andDictionary:userDictionary];
            [self.allUsersArray addObject: currentUser];
        }
    }
}


#pragma mark IBAction methods

- (IBAction)segueToMap:(id)sender {
//    CATransition *transition = [CATransition animation];
//    transition.duration = 0.3;
//    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//    transition.type = kCATransitionPush;
//    transition.subtype = kCATransitionFromRight;
//    [self.view.window.layer addAnimation:transition forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.allUsersArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLYFriendCell *cell = (FLYFriendCell *)[tableView dequeueReusableCellWithIdentifier:@"friendCell" forIndexPath:indexPath];
    FLYUser *flyUser = [self.allUsersArray objectAtIndex:indexPath.row];
    
//    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        cell.flyUser = flyUser;
        cell.fullnameLabel.text = [NSString stringWithFormat:@"%@ %@", flyUser.firstName, flyUser.lastName];
        cell.username.text = flyUser.userName;
    
        //if friend, set button to selected
        if ([self isFriend:flyUser.uid]) cell.addButton.selected = YES;
        else cell.addButton.selected = NO;
//        } completion:NULL];
    return cell;
}

- (BOOL)isFriend:(NSString *)friendUID{
    return ([self.friendsDictionary objectForKey:friendUID]);
}

- (BOOL)isTrueFriend:(NSString *)friendUID{
    return ([self.friendsDictionary objectForKey:friendUID] && [[self.friendsDictionary objectForKey:friendUID] boolValue] == true);
}


#pragma mark - Lazy Instantiation

- (NSMutableDictionary*)allUsersDictionary{
    if(!_allUsersDictionary){
        _allUsersDictionary = [[NSMutableDictionary alloc] init];
    }
    return _allUsersDictionary;
}

- (NSMutableArray *)allUsersArray{
    if (!_allUsersArray) {
        _allUsersArray = [[NSMutableArray alloc] init];
    }
    return _allUsersArray;
}

- (NSMutableDictionary *)friendsDictionary{
    if (!_friendsDictionary) {
        _friendsDictionary = [[NSMutableDictionary alloc] init];
    }
    return _friendsDictionary;
}



@end
