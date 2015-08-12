
//
//  FLYPulseImageUtils.m
//  Fly
//
//  Created by Kevin Yang on 8/10/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYPulseImageUtils.h"

@implementation FLYPulseImageUtils

+ (UIImage *)imageFromText:(NSString *)text
{
    UIFont *font = [UIFont systemFontOfSize:40.0];
    CGSize size  = [text sizeWithAttributes:@{NSFontAttributeName:font}];
    UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    [text drawAtPoint:CGPointMake(0.0, 0.0) withAttributes:@{NSFontAttributeName:font}];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
