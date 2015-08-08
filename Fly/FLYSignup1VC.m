//
//  FLYSignup1VC.m
//  Fly
//
//  Created by Kevin Yang on 7/25/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYSignup1VC.h"
#import "FLYAppDelegate.h"
#import "FLYSignup2VC.h"

@interface FLYSignup1VC () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *firstname;
@property (weak, nonatomic) IBOutlet UITextField *lastname;
@property (weak, nonatomic) IBOutlet UITextField *email;
@end

@implementation FLYSignup1VC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.firstname becomeFirstResponder];
//    [self setupKeyboards];
}


#pragma mark Processing Methods

- (BOOL)areTextFieldsFilled{
    NSString *firstname = self.firstname.text;
    NSString *lastname = self.lastname.text;
    NSString *email = self.email.text;

    if(firstname.length == 0 || lastname.length == 0 || email.length == 0){
        //warn user to fill in all fields
        [FLYAppDelegate alertWithTitle:@"Oops" andMessage:@"You forgot something"];
        return NO;
    }
    
    return YES;
}


#pragma mark UITextFieldDelegate Methods

//- (void)setupKeyboards
//{
//    self.firstname.returnKeyType = UIReturnKeyNext;
//    self.lastname.returnKeyType = UIReturnKeyNext;
//    self.email.keyboardType = UIKeyboardTypeEmailAddress;
//    [self.firstname setAutocorrectionType:UITextAutocorrectionTypeNo];
//    [self.lastname setAutocorrectionType:UITextAutocorrectionTypeNo];
//    [self.email setAutocorrectionType:UITextAutocorrectionTypeNo];
//
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.firstname) {
        [self.lastname becomeFirstResponder];
    }else if(textField == self.lastname){
        [self.email becomeFirstResponder];
    }else if(textField == self.email){
        [self continueHelper];
    }
    [textField resignFirstResponder];
    return YES;
}

- (void)resignAllResponders{
    [self.firstname resignFirstResponder];
    [self.lastname resignFirstResponder];
    [self.email resignFirstResponder];
}

#pragma mark IBAction Methods

- (IBAction)continue:(id)sender {
    [self continueHelper];
}

- (void)continueHelper{
    [self resignAllResponders];
    if([self areTextFieldsFilled]){
        [self performSegueWithIdentifier:@"signup2" sender:self];
    }
}

- (IBAction)cancel:(id)sender {
    [self resignAllResponders];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"signup2"]) {
        FLYSignup2VC *vc = [segue destinationViewController];
        
        vc.firstname = self.firstname.text;
        vc.lastname = self.lastname.text;
        vc.email = self.email.text;
        
    }
}


@end
