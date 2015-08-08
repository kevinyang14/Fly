//
//  FLYUser.m
//  Fly
//
//  Created by Kevin Yang on 8/1/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYUser.h"

@implementation FLYUser

- (id)initWithUID:(NSString *)uid andDictionary:(NSDictionary *)userDictionary
{
    self = [super init];
    if(self) {
        _uid = uid;
        _firstName = [userDictionary valueForKey:@"firstname"];
        _lastName = [userDictionary valueForKey:@"lastname"];
        _userName = [userDictionary valueForKey:@"username"];
    }
    return self;
}

@end
