//
//  FLYMapVC.m
//  Fly
//
//  Created by Kevin Yang on 7/29/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYMapVC.h"
#import "FLYAppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import <Mapkit/MapKit.h>
#import "FLYUserMetadata.h"

@interface FLYMapVC () <CLLocationManagerDelegate, MKMapViewDelegate>
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSMutableDictionary *userLocations;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pulseBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *peopleBarButton;
@property (nonatomic, assign) BOOL isZoomedHome;
@end

@implementation FLYMapVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLocationManager];
    [self setupMap];
    [self setupFirebase];
    [self setupUI];
}

- (NSMutableDictionary *)userLocations{
    if (!_userLocations) {
        _userLocations = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    return _userLocations;
}

#pragma mark Setup methods

- (void)setupUI{
    UINavigationBar *navBar = self.navigationController.navigationBar;
    [navBar setBackgroundImage:[UIImage imageNamed:@"flyTopbar"] forBarMetrics:UIBarMetricsDefault];
    [navBar setShadowImage:[UIImage new]];
    
    self.pulseBarButton.title = @"";
    self.peopleBarButton.title = @"";
    self.pulseBarButton.image = [[UIImage imageNamed:@"pulse"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    self.peopleBarButton.image = [[UIImage imageNamed:@"addPeople"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)setupLocationManager{
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    self.mapView.showsUserLocation = YES;
    [self.locationManager startUpdatingLocation];
}

- (void)setupMap{
    self.mapView.delegate = self;
    self.isZoomedHome = NO;
}

#pragma mark Firebase methods

- (void)setupFirebase{
    Firebase *userLocationsRef = [[FLYAppDelegate flyRef] childByAppendingPath:@"userLocations"];
    
    // Observe for when users are added
    [userLocationsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        [self addUserToMap:snapshot.value withId:snapshot.key];
    }];
    
    // or changed
    [userLocationsRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        if(![snapshot.key isEqualToString:[FLYAppDelegate flyRef].authData.uid]){
            NSDictionary* newUser = snapshot.value;
            FLYUserMetadata* oldUserMetadata = [self.userLocations objectForKey:snapshot.key];
            [self animateUser:oldUserMetadata toNewPosition:newUser];
        }
    }];
    //
    //    // Observe for when buses are removed
    //    [userLocationsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
    //        FBusMetadata* busMetadata = [self.busLocations objectForKey:snapshot.name];
    //        [self.busLocations removeObjectForKey:snapshot.name];
    //        [self.map removeAnnotation:busMetadata.pin];
    //    }];
}

- (void)saveUserLocation:(MKUserLocation *)userLocation{
    Firebase *flyRef = [FLYAppDelegate flyRef];
    Firebase *userLocationRef = [[flyRef childByAppendingPath:@"userLocations"] childByAppendingPath:flyRef.authData.uid];
    
    NSNumber *latitude = [NSNumber numberWithDouble:userLocation.location.coordinate.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:userLocation.location.coordinate.longitude];
    NSDictionary *location = @{
                               @"lat": latitude,
                               @"long": longitude
                               };
    
    [userLocationRef updateChildValues:location];
}

#pragma mark Map manipulation

- (void) addUserToMap:(NSDictionary *)user withId:(NSString *)key {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *myUID = [FLYAppDelegate flyRef].authData.uid;
        if(user && ![self.userLocations objectForKey:key] && ![key isEqualToString:myUID]) {
            MKPointAnnotation *userPin = [[MKPointAnnotation alloc] init];
            userPin.title = @"user";
            [userPin setCoordinate:CLLocationCoordinate2DMake([[user valueForKey:@"lat"] doubleValue], [[user valueForKey:@"long"] doubleValue])];
            
            FLYUserMetadata* userMetadata = [[FLYUserMetadata alloc] init];
            userMetadata.metadata = user;
            userMetadata.pin = userPin;
            
            [self.userLocations setObject:userMetadata forKey:key];
            [self.mapView addAnnotation:userPin];
        }
    });
}

- (void) animateUser:(FLYUserMetadata *)oldUserMetadata toNewPosition:(NSDictionary *)newUser {
    dispatch_async(dispatch_get_main_queue(), ^{
        MKPointAnnotation *userPin = oldUserMetadata.pin;
        MKAnnotationView *userView = [self.mapView viewForAnnotation:userPin];
        if(userView) {
            CLLocationCoordinate2D newCoord = CLLocationCoordinate2DMake([[newUser objectForKey:@"lat"] doubleValue], [[newUser objectForKey:@"long"] doubleValue]);
            MKMapPoint mapPoint = MKMapPointForCoordinate(newCoord);
            
            CGPoint toPos;
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
                toPos = [self.mapView convertCoordinate:newCoord toPointToView:self.mapView];
            } else {
                CGFloat zoomFactor =  self.mapView.visibleMapRect.size.width / self.mapView.bounds.size.width;
                toPos.x = mapPoint.x/zoomFactor;
                toPos.y = mapPoint.y/zoomFactor;
            }
            
            if (MKMapRectContainsPoint(self.mapView.visibleMapRect, mapPoint)) {
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
                animation.fromValue = [NSValue valueWithCGPoint:userView.center];
                animation.toValue = [NSValue valueWithCGPoint:toPos];
                animation.duration = 1.5;
                animation.delegate = userView;
                animation.fillMode = kCAFillModeForwards;
                [userView.layer addAnimation:animation forKey:@"positionAnimation"];
            }
            
            userView.center = toPos;
            oldUserMetadata.metadata = newUser;
            [userPin setCoordinate:newCoord];
        }
    });
}

#pragma mark MKMapDelegate

- (void)homeWithFancyBuildings{
    if ([self.mapView respondsToSelector:@selector(camera)]) {
        [self.mapView setShowsBuildings:YES];
        MKMapCamera *newCamera = [[self.mapView camera] copy];
        [newCamera setCenterCoordinate:self.mapView.userLocation.location.coordinate];
        [newCamera setPitch:20.0];
        [newCamera setHeading:270.0];
        [newCamera setAltitude:1200.0];
        [self.mapView setCamera:newCamera animated:YES];
    }
}

- (void)addMarkerToLocation:(CLLocationCoordinate2D)locationCoordinate
{
    // Declare the annotation `point` and set its coordinates, title, and subtitle
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = locationCoordinate;
    point.title = @"Come over to SigChi";
    point.subtitle = @"We are throwing an all-campus!";
    [self.mapView addAnnotation:point];
    [self.mapView setRegion:MKCoordinateRegionMake(locationCoordinate, MKCoordinateSpanMake(0.001, 0.001)) animated:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    NSLog(@"didUpdateUserLocation");
    [self saveUserLocation:userLocation];
    if (!self.isZoomedHome) {
        [self homeWithFancyBuildings];
        self.isZoomedHome = YES;
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    if(annotation == mapView.userLocation) return nil;
    MKAnnotationView *emojiPin = [[MKAnnotationView alloc ] initWithAnnotation:annotation reuseIdentifier:@"emojiPin"];
    if ([[annotation title] isEqualToString:@"user"]){
        emojiPin.image = [UIImage imageNamed:@"happy"];
    }
    return emojiPin;
}

- (IBAction)home:(id)sender {
    [self homeHelper];
}

- (void)homeHelper{
    [self.mapView setRegion:MKCoordinateRegionMake(self.mapView.userLocation.location.coordinate, MKCoordinateSpanMake(0.003, 0.003)) animated:YES];
}


#pragma mark requestAlwaysAuthorization

- (void)requestAlwaysAuthorization
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    // If the status is denied or only granted for when in use, display an alert
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusDenied) {
        NSString *title;
        title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Background location is not enabled";
        NSString *message = @"To use background location you must turn on 'Always' in the Location Services Settings";
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Settings", nil];
        [alertView show];
    }
    // The user has not enabled any location services. Request background authorization.
    else if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestAlwaysAuthorization];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // Send the user to the Settings for this app
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }
}


//- (void)saveUserLocation:(MKUserLocation *)userLocation
//{
//    Firebase *flyRef = [FLYAppDelegate flyRef];
//    NSNumber *latitude = [NSNumber numberWithDouble:userLocation.location.coordinate.latitude];
//    NSNumber *longitude = [NSNumber numberWithDouble:userLocation.location.coordinate.longitude];
//
//    NSDictionary *location = @{
//                               @"lat": latitude,
//                               @"long": longitude
//                               };
//
//    [[[flyRef childByAppendingPath:@"users"]
//      childByAppendingPath:flyRef.authData.uid] updateChildValues:location];
//}


@end
