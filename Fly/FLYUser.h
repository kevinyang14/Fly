//
//  FLYUser.h
//  Fly
//
//  Created by Kevin Yang on 8/1/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLYUser : NSObject

@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;
@property (nonatomic, strong) NSString *userName;

- (id)initWithUID:(NSString *)uid andDictionary:(NSDictionary *)userDictionary;

@end
