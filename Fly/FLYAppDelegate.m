//
//  AppDelegate.m
//  Fly
//
//  Created by Kevin Yang on 7/25/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYAppDelegate.h"
#import "FLYColor.h"
#import "FLYWelcomeVC.h"
#import "FLYMapVC.h"


static NSString * const kFirebaseURL = @"https://flyapp.firebaseio.com";
@interface FLYAppDelegate ()
@end

@implementation FLYAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupUI];
    NSLog(@"after set up UI");
    [self toggleLogin];
    return YES;
}

- (void)setupUI{
    [[UITextField appearance] setTintColor:[FLYColor flyYellow]];
    if([UINavigationBar conformsToProtocol:@protocol(UIAppearanceContainer)]) {
        [UINavigationBar appearance].tintColor = [UIColor grayColor];
    }
}

- (void)toggleLogin{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main"
                                                             bundle: nil];
    Firebase *flyRef = [FLYAppDelegate flyRef];

    if (flyRef.authData) {
        NSLog(@"LOGGED IN");
        FLYMapVC *mapView = (FLYMapVC *)[mainStoryboard instantiateViewControllerWithIdentifier:@"FLYMapVC"];
        self.window.rootViewController = mapView;
    } else {
        NSLog(@"NOT LOGGED IN");
        FLYWelcomeVC *welcomeView = (FLYWelcomeVC *)[mainStoryboard instantiateViewControllerWithIdentifier:@"FLYWelcomeVC"];
        self.window.rootViewController = welcomeView;
    }
}

#pragma mark Firebase methods

+(Firebase *)flyRef{
    return [[Firebase alloc] initWithUrl:kFirebaseURL];
}

+(NSString *)userUID{
    return [FLYAppDelegate flyRef].authData.uid;
}

#pragma mark Helper methods

+(void)alertWithTitle:(NSString *)title andMessage:(NSString *)msg
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:msg
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
