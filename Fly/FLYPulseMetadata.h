//
//  FLYPulseMetadata.h
//  Fly
//
//  Created by Kevin Yang on 8/10/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface FLYPulseMetadata : NSObject
@property (nonatomic, strong) NSDictionary *metadata;
@property (nonatomic, strong) MKPointAnnotation *pin;
@end
