//
//  FLYPulseVC.m
//  Fly
//
//  Created by Kevin Yang on 8/9/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYPulseVC.h"
#import "FLYAppDelegate.h"

@interface FLYPulseVC () <UITextFieldDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emojiTextField;
@end

@implementation FLYPulseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.emojiTextField becomeFirstResponder];
    [self.locationManager startUpdatingLocation];
}

- (IBAction)segueToMap:(id)sender {
    [self segueToMapHelper];
}

- (void)segueToMapHelper{
    [self.emojiTextField resignFirstResponder];
//    CATransition *transition = [CATransition animation];
//    transition.duration = 0.3;
//    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//    transition.type = kCATransitionPush;
//    transition.subtype = kCATransitionFromLeft;
//    [self.view.window.layer addAnimation:transition forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark Processing Methods

- (BOOL)isTextFieldFilled{
    NSString *emoji = self.emojiTextField.text;
    
    if(emoji.length == 0){
        //warn user to fill in all fields
        [FLYAppDelegate alertWithTitle:@"Oops" andMessage:@"You forgot something"];
        return NO;
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self savePulseFirebase];
    return YES;
}

- (IBAction)sendPulse:(id)sender {
    [self savePulseFirebase];
}

#pragma mark CLLocationManager Delegate Methods

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    NSLog(@"did update location");
}


#pragma mark Firebase Methods

- (void)savePulseFirebase{
    if ([self isTextFieldFilled]) {
        NSString *emoji = self.emojiTextField.text;
        Firebase *pulseRef = [[FLYAppDelegate flyRef] childByAppendingPath:@"pulseLocations"];
        Firebase *newPulseRef = [pulseRef childByAutoId];
        NSNumber *latitude = [NSNumber numberWithDouble:self.locationManager.location.coordinate.latitude];
        NSNumber *longitude = [NSNumber numberWithDouble:self.locationManager.location.coordinate.longitude];
        NSDictionary *newPulse = @{
                                   @"sender":[FLYAppDelegate userUID],
                                   @"emojis":emoji,
                                   @"lat": latitude,
                                   @"long": longitude,
                                   };
        //add sender name here
        [newPulseRef setValue:newPulse withCompletionBlock:^(NSError *error, Firebase *ref) {
            NSLog(@"pulse saved");
            self.emojiTextField.text = @"pulse saved!";
//            [self.emojiTextField resignFirstResponder];
            [self segueToMapHelper];
        }];
    }
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
