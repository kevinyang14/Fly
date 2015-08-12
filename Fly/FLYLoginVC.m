//
//  FLYLoginVC.m
//  Fly
//
//  Created by Kevin Yang on 7/25/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYLoginVC.h"
#import "FLYAppDelegate.h"
#import "SVProgressHUD.h"

@interface FLYLoginVC () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *password;
@end

@implementation FLYLoginVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.email becomeFirstResponder];
//    [self setupKeyboards];
}

#pragma mark Processing Methods

- (BOOL)areTextFieldsFilled{
    NSString *username = self.email.text;
    NSString *password = self.password.text;
    
    if(username.length == 0 || password.length == 0){
        [FLYAppDelegate alertWithTitle:@"Oops" andMessage:@"You forgot something"];
        return NO;
    }
    
    return YES;
}

- (void)resignAllResponders{
    [self.email resignFirstResponder];
    [self.password resignFirstResponder];
}

#pragma mark UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.email) {
        [self.password becomeFirstResponder];
    }else if(textField == self.password){
        [self loginHelper];
    }
    [textField resignFirstResponder];
    return YES;
}

#pragma mark IBAction Methods
- (IBAction)login:(id)sender {
    [self loginHelper];
}

- (void)loginHelper{
    [self resignAllResponders];
    if([self areTextFieldsFilled]){
        [self loginWithFirebase];
    }
}

- (IBAction)cancel:(id)sender {
    [self resignAllResponders];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark Firebase Methods

- (void)loginWithFirebase{
    [SVProgressHUD show];
    NSString *email = self.email.text;
    NSString *password = self.password.text;
    Firebase *flyRef = [FLYAppDelegate flyRef];
    [flyRef authUser:email password:password withCompletionBlock:^(NSError *error, FAuthData *authData) {
    if (error) {
        NSLog(@"error %@", error);
        [SVProgressHUD showErrorWithStatus:@"Fail Whale 🐳"];
    } else {
        NSLog(@"login successful");
        [self createFriendshipBranch];
        [SVProgressHUD showSuccessWithStatus:@"Logged in 😇"];
        [self performSegueWithIdentifier:@"loginToMap" sender:self];
    }
    }];
    
}

- (void)createFriendshipBranch{
    Firebase *flyRef = [FLYAppDelegate flyRef];
    Firebase *friendshipRef = [[flyRef childByAppendingPath:@"friendship"] childByAppendingPath:flyRef.authData.uid];
    NSDictionary *friendship = @{};
    [friendshipRef updateChildValues:friendship];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
