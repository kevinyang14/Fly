//
//  FLYMapVC.m
//  Fly
//
//  Created by Kevin Yang on 7/29/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYMapVC.h"
#import <CoreLocation/CoreLocation.h>
#import <Mapkit/MapKit.h>
#import "FLYAppDelegate.h"
#import "FLYUserMetadata.h"
#import "FLYPulseMetadata.h"
#import "FLYPulseVC.h"
#import "FLYPulseCell.h"
#import "FLYPulseImageUtils.h"
#import "FLYColor.h"

@interface FLYMapVC () <CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (nonatomic, assign) BOOL isZoomedHome;

//UI
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pulseBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *peopleBarButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

//Data Storage
@property (strong, nonatomic) NSMutableDictionary *userLocationsDictionary;               //all user information: userID -> userMetaData
@property (strong, nonatomic) NSMutableDictionary *pulseLocationsDictionary;    //all pulse information
@property (strong, nonatomic) NSMutableArray *pulseLocationsArray;              //sorted array of pulse keys

@end

@implementation FLYMapVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLocationManager];
    [self setupMap];
    [self setupFirebase];
    [self setupUI];
}

#pragma mark Lazy Instantiation

- (NSMutableDictionary *)userLocationsDictionary{
    if (!_userLocationsDictionary) {
        _userLocationsDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
    }
    return _userLocationsDictionary;
}
- (NSMutableDictionary *)pulseLocationsDictionary{
    if(!_pulseLocationsDictionary){
        _pulseLocationsDictionary = [[NSMutableDictionary alloc] init];
    }
    return _pulseLocationsDictionary;
}
- (NSMutableArray *)pulseLocationsArray{
    if(!_pulseLocationsArray){
        _pulseLocationsArray = [[NSMutableArray alloc] init];
    }
    return _pulseLocationsArray;
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
    
    self.tableView.allowsMultipleSelection = NO;
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
    Firebase *pulseLocationsRef = [[FLYAppDelegate flyRef] childByAppendingPath:@"pulseLocations"];
    [self setupUserLocationsFirebase:userLocationsRef];
    [self setupPulseLocationsFirebase:pulseLocationsRef];
}

- (void)setupPulseLocationsFirebase:(Firebase *)pulseLocationsRef{
    // Listen for when USERS are added
    [pulseLocationsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        [self addPulseToArraySorted:snapshot.key];
        [self addPulseToMap:snapshot.value withId:snapshot.key];
    }];
    
    // or changed
    [pulseLocationsRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary* newPulse = snapshot.value;
        FLYPulseMetadata* oldPulseMetadata = [self.pulseLocationsDictionary objectForKey:snapshot.key];
        [self animatePin:oldPulseMetadata.pin toNewPosition:newPulse];
        oldPulseMetadata.metadata = newPulse;
    }];
    
    // or removed
    [pulseLocationsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        FLYPulseMetadata* pulseMetadata = [self.pulseLocationsDictionary objectForKey:snapshot.key];
        [self.pulseLocationsDictionary removeObjectForKey:snapshot.key];
        [self.pulseLocationsArray removeObject:snapshot.key];
        [self.mapView removeAnnotation:pulseMetadata.pin];
    }];
}

- (void)setupUserLocationsFirebase:(Firebase *)userLocationsRef{
    // Listen for when USERS are added
    [userLocationsRef observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        [self addUserToMap:snapshot.value withId:snapshot.key];
    }];
    
    // or changed
    [userLocationsRef observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        if(![snapshot.key isEqualToString:[FLYAppDelegate flyRef].authData.uid]){
            NSDictionary* newUser = snapshot.value;
            FLYUserMetadata* oldUserMetadata = [self.userLocationsDictionary objectForKey:snapshot.key];
            [self animatePin:oldUserMetadata.pin toNewPosition:newUser];
            oldUserMetadata.metadata = newUser;
        }
    }];
    
    // or removed
    [userLocationsRef observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        FLYUserMetadata* userMetadata = [self.userLocationsDictionary objectForKey:snapshot.key];
        [self.userLocationsDictionary removeObjectForKey:snapshot.key];
        [self.mapView removeAnnotation:userMetadata.pin];
    }];
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


- (void)addPulseToArraySorted:(NSString *)pulseKey{
    NSUInteger newIndex = [self.pulseLocationsArray indexOfObject:pulseKey
                                                    inSortedRange:(NSRange){0, [self.pulseLocationsArray count]}
                                                          options:NSBinarySearchingInsertionIndex
                                                  usingComparator: ^(NSString *key1, NSString *key2) {
                                                      return [key2 compare:key1];
                                                  }];
    [self.pulseLocationsArray insertObject:pulseKey atIndex:newIndex];
}


//- (void)addAllPulsesOnMap:(NSDictionary *)allPulses{
//    for (NSString *idKey in allPulses) {
//        NSDictionary *value = [allPulses objectForKey:idKey];
//        [self addPulseToMap:value withId:idKey];
//    }
//}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.pulseLocationsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FLYPulseCell *cell = (FLYPulseCell*)[tableView dequeueReusableCellWithIdentifier:@"messageCell" forIndexPath:indexPath];
    NSString *idKey = [self.pulseLocationsArray objectAtIndex:indexPath.row];
    FLYPulseMetadata *pulseMetadata = [self.pulseLocationsDictionary objectForKey:idKey];
    NSDictionary *pulse = pulseMetadata.metadata;
    
    cell.emojiLabel.text = [pulse objectForKey:@"emojis"];
    cell.senderLabel.text = [pulse objectForKey:@"senderName"];
    NSString *orbImageName = [NSString stringWithFormat:@"orb%d",arc4random()%4];
    cell.timeBomb.image = [UIImage imageNamed:orbImageName];
    cell.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.0];
    return cell;
}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    FLYPulseCell *cell = (FLYPulseCell*)[tableView dequeueReusableCellWithIdentifier:@"messageCell" forIndexPath:indexPath];
//    NSString *idKey = [self.pulseLocationsArray objectAtIndex:indexPath.row];
//    NSDictionary *pulse = [self.pulseLocationsDictionary objectForKey:idKey];
//    cell.emojiLabel.text = [pulse objectForKey:@"emojis"];
//    
//    NSString *senderName = [pulse objectForKey:@"senderName"];
//    NSLog(@"senderName %@", senderName);
//    if (!senderName) cell.senderLabel.text = @"Walt Disney";
//    else cell.senderLabel.text = senderName;
//    
//    int orbNum = arc4random()%4;
//    NSString *orbImageName = [NSString stringWithFormat:@"orb%d",orbNum];
//
//    cell.timeBomb.image = [UIImage imageNamed:orbImageName];
//    cell.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.0];
//    
//    //selection yellow highlight
////    UIView *customColorView = [[UIView alloc] init];
////    customColorView.backgroundColor = [FLYColor flyYellow];
////    cell.selectedBackgroundView = customColorView;
//    return cell;
//}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *idKey = [self.pulseLocationsArray objectAtIndex:indexPath.row];
    FLYPulseMetadata *pulseMetadata = [self.pulseLocationsDictionary objectForKey:idKey];
    NSDictionary *pulse = pulseMetadata.metadata;
    
    double latitude =[[pulse objectForKey:@"lat"] doubleValue];
    double longitude = [[pulse objectForKey:@"long"] doubleValue];
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    [self goToPulseLocation:coordinate];
}


//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSString *idKey = [self.pulseLocationsArray objectAtIndex:indexPath.row];
//    NSDictionary *pulse = [self.pulseLocationsDictionary objectForKey:idKey];
//    double latitude =[[pulse objectForKey:@"lat"] doubleValue];
//    double longitude = [[pulse objectForKey:@"long"] doubleValue];
//
//    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
//    [self goToPulseLocation:coordinate];
//}

#pragma mark Map manipulation

- (void) addUserToMap:(NSDictionary *)user withId:(NSString *)key {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *myUID = [FLYAppDelegate flyRef].authData.uid;
        if(user && ![self.userLocationsDictionary objectForKey:key] && ![key isEqualToString:myUID]) {
            MKPointAnnotation *userPin = [[MKPointAnnotation alloc] init];
            userPin.title = @"user";
            double latitude =[[user objectForKey:@"lat"] doubleValue];
            double longitude = [[user objectForKey:@"long"] doubleValue];
            
            [userPin setCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
            
            FLYUserMetadata* userMetadata = [[FLYUserMetadata alloc] init];
            userMetadata.metadata = user;
            userMetadata.pin = userPin;
            
            [self.userLocationsDictionary setObject:userMetadata forKey:key];
            [self.mapView addAnnotation:userPin];
        }
    });
}

- (void) addPulseToMap:(NSDictionary *)pulse withId:(NSString *)key {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(pulse && ![self.pulseLocationsDictionary objectForKey:key]) {
            MKPointAnnotation *pulsePin = [[MKPointAnnotation alloc] init];
            pulsePin.title = [pulse objectForKey:@"emojis"];
            double latitude =[[pulse objectForKey:@"lat"] doubleValue];
            double longitude = [[pulse objectForKey:@"long"] doubleValue];
            
            [pulsePin setCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
            
            FLYPulseMetadata* pulseMetadata = [[FLYPulseMetadata alloc] init];
            pulseMetadata.metadata = pulse;
            pulseMetadata.pin = pulsePin;
            
            [self.pulseLocationsDictionary setObject:pulseMetadata forKey:key];
            [self.tableView reloadData];
            [self.mapView addAnnotation:pulsePin];
        }
    });
}

//- (void) addPulseToMap:(NSDictionary *)pulse withId:(NSString *)key {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if(pulse) {
//            MKPointAnnotation *pulsePin = [[MKPointAnnotation alloc] init];
//            
//            double latitude =[[pulse objectForKey:@"lat"] doubleValue];
//            double longitude = [[pulse objectForKey:@"long"] doubleValue];
//            [pulsePin setCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
//            pulsePin.title = [pulse objectForKey:@"emojis"];
//            NSLog(@"emojis %@", pulsePin.title);
//            [self.mapView addAnnotation:pulsePin];
//        }
//    });
//}

- (void) animatePin:(MKPointAnnotation *)oldPin toNewPosition:(NSDictionary *)newPinLocation {
    dispatch_async(dispatch_get_main_queue(), ^{
        MKAnnotationView *pinView = [self.mapView viewForAnnotation:oldPin];
        if(pinView) {
            double latitude = [[newPinLocation objectForKey:@"lat"] doubleValue];
            double longitude = [[newPinLocation objectForKey:@"long"] doubleValue];
            
            CLLocationCoordinate2D newCoord = CLLocationCoordinate2DMake(latitude, longitude);
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
                animation.fromValue = [NSValue valueWithCGPoint:pinView.center];
                animation.toValue = [NSValue valueWithCGPoint:toPos];
                animation.duration = 1.5;
                animation.delegate = pinView;
                animation.fillMode = kCAFillModeForwards;
                [pinView.layer addAnimation:animation forKey:@"positionAnimation"];
            }

            pinView.center = toPos;
            [oldPin setCoordinate:newCoord];
        }
    });
}

//- (void) animateUser:(FLYUserMetadata *)oldUserMetadata toNewPosition:(NSDictionary *)newUser {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        MKPointAnnotation *userPin = oldUserMetadata.pin;
//        MKAnnotationView *userView = [self.mapView viewForAnnotation:userPin];
//        if(userView) {
//            CLLocationCoordinate2D newCoord = CLLocationCoordinate2DMake([[newUser objectForKey:@"lat"] doubleValue], [[newUser objectForKey:@"long"] doubleValue]);
//            MKMapPoint mapPoint = MKMapPointForCoordinate(newCoord);
//            
//            CGPoint toPos;
//            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
//                toPos = [self.mapView convertCoordinate:newCoord toPointToView:self.mapView];
//            } else {
//                CGFloat zoomFactor =  self.mapView.visibleMapRect.size.width / self.mapView.bounds.size.width;
//                toPos.x = mapPoint.x/zoomFactor;
//                toPos.y = mapPoint.y/zoomFactor;
//            }
//            
//            if (MKMapRectContainsPoint(self.mapView.visibleMapRect, mapPoint)) {
//                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
//                animation.fromValue = [NSValue valueWithCGPoint:userView.center];
//                animation.toValue = [NSValue valueWithCGPoint:toPos];
//                animation.duration = 1.5;
//                animation.delegate = userView;
//                animation.fillMode = kCAFillModeForwards;
//                [userView.layer addAnimation:animation forKey:@"positionAnimation"];
//            }
//            
//            userView.center = toPos;
//            oldUserMetadata.metadata = newUser;
//            [userPin setCoordinate:newCoord];
//        }
//    });
//}

#pragma mark MKMapDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    NSLog(@"didUpdateUserLocation");
    [self saveUserLocation:userLocation];
    [self goHome];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    //my annotation
    if(annotation == mapView.userLocation) return nil;
    
    //friends annotations
    MKAnnotationView *emojiPin = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"emojiPin"];
    if ([[annotation title] isEqualToString:@"user"]) emojiPin.image = [UIImage imageNamed:@"happy"];
    
    //pulse annotations
    else emojiPin.image = [FLYPulseImageUtils imageFromText:[annotation title]];
    
    return emojiPin;
}

- (IBAction)home:(id)sender {
    [self goHome];
}

- (void)goHome{
    [self.mapView setRegion:MKCoordinateRegionMake(self.mapView.userLocation.location.coordinate, MKCoordinateSpanMake(0.045, 0.045)) animated:YES];
}

- (void)goToPulseLocation:(CLLocationCoordinate2D)coordinate{
    [self.mapView setRegion:MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.0005, 0.0005)) animated:YES];
}

- (void)goHomeWithBuildings{
    if (!self.isZoomedHome) {
        if ([self.mapView respondsToSelector:@selector(camera)]) {
            [self.mapView setShowsBuildings:YES];
            MKMapCamera *newCamera = [[self.mapView camera] copy];
            [newCamera setCenterCoordinate:self.mapView.userLocation.location.coordinate];
            [newCamera setPitch:20.0];
            [newCamera setHeading:270.0];
            [newCamera setAltitude:700.0];
            [self.mapView setCamera:newCamera animated:YES];
        }
        self.isZoomedHome = YES;
    }
}


#pragma mark Segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pulseSegue"])
    {
        FLYPulseVC *vc = [segue destinationViewController];
        vc.locationManager = self.locationManager;
    }
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


@end
