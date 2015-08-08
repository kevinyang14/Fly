//
//  FLYSignup2VC.m
//  Fly
//
//  Created by Kevin Yang on 7/25/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYSignup2VC.h"
#import "FLYAppDelegate.h"

@interface FLYSignup2VC () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;

@end

@implementation FLYSignup2VC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.username becomeFirstResponder];
}

#pragma mark Firebase Methods

- (void)signupWithFirebaseAuth{
    NSString *email = self.email;
    NSString *password = self.password.text;

    Firebase *flyRef = [FLYAppDelegate flyRef];
    [flyRef createUser:email password:password
    withValueCompletionBlock:^(NSError *error, NSDictionary *result) {
        if (error) {
            NSLog(@"error %@", error);
        } else {
            NSString *uid = [result objectForKey:@"uid"];
            NSLog(@"Successfully created user account with uid: %@", uid);
            [self saveUserInfo];
        }
    }];
}

- (void)saveUserInfo{
    NSString *email = self.email;
    NSString *password = self.password.text;
    NSString *username = self.username.text;
    NSString *firstname = self.firstname;
    NSString *lastname = self.lastname;
    
    Firebase *flyRef = [FLYAppDelegate flyRef];
    [flyRef authUser:email password:password withCompletionBlock:^(NSError *error, FAuthData *authData) {
    if (error) {
        NSLog(@"error %@", error);
    } else {
        NSLog(@"saving user data...");
        NSDictionary *newUser = @{
                                  @"provider": authData.provider,
                                  @"email": authData.providerData[@"email"],
                                  @"firstname" : firstname,
                                  @"lastname" : lastname,
                                  @"username" : username
                                  };
        
        [[[flyRef childByAppendingPath:@"users"]
        childByAppendingPath:authData.uid] setValue:newUser];
        [self performSegueWithIdentifier:@"signupToMap" sender:self];
        [self createFriendshipBranch];
    }
    }];
}

- (void)createFriendshipBranch{
    Firebase *flyRef = [FLYAppDelegate flyRef];
    Firebase *friendshipRef = [[flyRef childByAppendingPath:@"friendship"] childByAppendingPath:flyRef.authData.uid];
    NSDictionary *friendship = @{};
    [friendshipRef updateChildValues:friendship];
}

#pragma mark IBAction Methods

- (IBAction)createAccount:(id)sender{
    [self createAccountHelper];
}

- (void)createAccountHelper{
    if ([self areTextFieldsFilled]) {
        [self signupWithFirebaseAuth];
    }
}

- (IBAction)back:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark Processing Methods

- (BOOL)areTextFieldsFilled{
    NSString *username = self.username.text;
    NSString *password = self.password.text;
    
    if(username.length == 0 || password.length == 0){
        //warn user to fill in all fields
        [FLYAppDelegate alertWithTitle:@"Oops" andMessage:@"You forgot something"];
        return NO;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.username) {
        [self.password becomeFirstResponder];
    }else if(textField == self.password){
        [self createAccountHelper];
    }
    [textField resignFirstResponder];
    return YES;
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
