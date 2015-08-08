//
//  FLYUserMetadata.h
//  Fly
//
//  Created by Kevin Yang on 7/30/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface FLYUserMetadata : NSObject
@property (nonatomic, strong) NSDictionary *metadata;
@property (nonatomic, strong) MKPointAnnotation *pin;
@end
