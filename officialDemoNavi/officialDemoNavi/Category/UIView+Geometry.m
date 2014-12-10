//
//  UIView+Geometry.m
//  officialDemoNavi
//
//  Created by LiuX on 14-8-25.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "UIView+Geometry.h"

@implementation UIView (Geometry)

- (CGFloat)width
{
    return self.bounds.size.width;
}

- (CGFloat)height
{
    return self.bounds.size.height;
}

- (CGFloat)left
{
    return self.frame.origin.x;
}

- (CGFloat)right
{
    return self.frame.origin.y;
}

- (void)setLeft:(CGFloat)x
{
    CGRect oldFrame = self.frame;
    CGRect newFrame = CGRectMake(x, oldFrame.origin.y, oldFrame.size.width, oldFrame.size.height);
    self.frame = newFrame;
}

- (void)setTop:(CGFloat)y
{
    CGRect oldFrame = self.frame;
    CGRect newFrame = CGRectMake(oldFrame.origin.x, y, oldFrame.size.width, oldFrame.size.height);
    self.frame = newFrame;
}

@end
