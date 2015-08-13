//
//  FLYAnimation.m
//  Fly
//
//  Created by Kevin Yang on 8/12/15.
//  Copyright (c) 2015 Fly. All rights reserved.
//

#import "FLYAnimation.h"
#import "FLYColor.h"

@implementation FLYAnimation

+(void)makeViewShine:(UIView*)view
{
    view.layer.shadowColor = [FLYColor flyYellow].CGColor;
    view.layer.shadowRadius = 10.0f;
    view.layer.shadowOpacity = 1.0f;
    view.layer.shadowOffset = CGSizeZero;
    
    
    [UIView animateWithDuration:0.7f delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationCurveEaseInOut | UIViewAnimationOptionRepeat | UIViewAnimationOptionAllowUserInteraction  animations:^{
        
        [UIView setAnimationRepeatCount:15];
        
        view.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
        
        
    } completion:^(BOOL finished) {
        
        view.layer.shadowRadius = 0.0f;
        view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    }];
}
@end
