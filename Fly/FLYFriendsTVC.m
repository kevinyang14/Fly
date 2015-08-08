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
@property (strong, nonatomic) NSMutableArray *friendSuggestionsArray;
@property (strong, nonatomic) NSMutableArray *friendRequestsArray;
@property (strong, nonatomic) NSMutableArray *friendsArray;
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

- (void)printFriendArrays{
    NSLog(@"friends %@", self.friendsArray);
    NSLog(@"friendRequests %@", self.friendRequestsArray);
    NSLog(@"friendSuggestionsArray %@", self.friendSuggestionsArray);
}

//----------------------------------------BUGGY: fix all friend request logic---------------------------------------//
- (void) setupFirebase{
    [SVProgressHUD show];
    Firebase *usersRef = [[FLYAppDelegate flyRef] childByAppendingPath:@"users"];
    Firebase *friendshipRef = [[FLYAppDelegate flyRef] childByAppendingPath:@"friendship"];
    [friendshipRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        [self processFriendships:snapshot.value];
        [usersRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            [self processAllUsers:snapshot.value];
            [self.tableView reloadData];
            [SVProgressHUD dismiss];
        }];
    }];
}


- (void) processAllUsers:(NSDictionary *)usersDictionary{
    for(NSString *uidKey in usersDictionary){
        if(![uidKey isEqualToString:[FLYAppDelegate flyRef].authData.uid]){
            FLYUser *user = [[FLYUser alloc] initWithUID:uidKey andDictionary:[usersDictionary valueForKey:uidKey]];
            //process friend suggestions
            if (![self.friendRequestsArray containsObject:uidKey] && ![self.friendsArray containsObject:uidKey] && ![self.friendSuggestionsArray containsObject:uidKey]) [self.friendSuggestionsArray addObject:uidKey];
            [self.allUsersDictionary setObject:user forKey:uidKey];
        }
    }
    NSLog(@"friendSuggestions %@", self.friendSuggestionsArray);
}

- (void) processFriendships:(NSDictionary *)friendshipDictionary{
    for(NSString *userKey in friendshipDictionary){    //loop through each user
        NSDictionary *userFriendsDictionary = [friendshipDictionary objectForKey:userKey];
        for(NSString *friendKey in userFriendsDictionary){  //loop through user's friends
            //process user friends
            if ([userKey isEqualToString:[FLYAppDelegate userUID]] && [[userFriendsDictionary objectForKey:friendKey] boolValue]) {
                if(![self.friendsArray containsObject:friendKey])[self.friendsArray addObject:friendKey];
            }
            //process friend requests
            if([friendKey isEqualToString:[FLYAppDelegate userUID]] && ![[userFriendsDictionary objectForKey:friendKey] boolValue]){
                if(![self.friendRequestsArray containsObject:friendKey])[self.friendRequestsArray addObject:userKey];
            }
        }
    }
    NSLog(@"friends %@", self.friendsArray);
    NSLog(@"friendRequests %@", self.friendRequestsArray);
}

#pragma mark IBAction methods

- (IBAction)segueToMap:(id)sender {
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [self.view.window.layer addAnimation:transition forKey:nil];
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = NSLocalizedString(@"Friends Requests", @"Friends Requests");
            break;
        case 1:
            sectionName = NSLocalizedString(@"Add New Friends", @"Add Friends");
            break;
            // ...
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return [self.friendRequestsArray count];
    }
    return [self.friendSuggestionsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLYFriendCell *cell = (FLYFriendCell *)[tableView dequeueReusableCellWithIdentifier:@"friendCell" forIndexPath:indexPath];
    NSString *uid = (indexPath.section == 0) ? [self.friendRequestsArray objectAtIndex:indexPath.row] : [self.friendSuggestionsArray objectAtIndex:indexPath.row];
    NSLog(@"uid %@", uid);
    FLYUser *flyUser = [self.allUsersDictionary objectForKey:uid];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        cell.flyUser = flyUser;
        cell.fullnameLabel.text = [NSString stringWithFormat:@"%@ %@", flyUser.firstName, flyUser.lastName];
        cell.username.text = flyUser.userName;
    } completion:NULL];
    return cell;
}

#pragma mark - Lazy Instantiation

- (NSMutableArray *)friendSuggestionsArray{
    if(!_friendSuggestionsArray){
        _friendSuggestionsArray = [[NSMutableArray alloc] init];
    }
    return _friendSuggestionsArray;
}

- (NSMutableArray *)friendRequestsArray{
    if(!_friendRequestsArray){
        _friendRequestsArray = [[NSMutableArray alloc] init];
    }
    return _friendRequestsArray;
}

- (NSMutableArray *)friendsArray{
    if(!_friendsArray){
        _friendsArray = [[NSMutableArray alloc] init];
    }
    return _friendsArray;
}


- (NSMutableDictionary*)allUsersDictionary{
    if(!_allUsersDictionary){
        _allUsersDictionary = [[NSMutableDictionary alloc] init];
    }
    return _allUsersDictionary;
}


@end
