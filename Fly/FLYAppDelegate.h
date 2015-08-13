//
//  AppDelegate.h
//  Fly
//
//  Created by Kevin Yang on 7/25/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>

@interface FLYAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
+(void)alertWithTitle:(NSString *)title andMessage:(NSString *)msg;
+(Firebase *)flyRef;
+(NSString *)userUID;
- (void)toggleLogin;
@end

