//
//  UIView+Geometry.h
//  officialDemoNavi
//
//  Created by LiuX on 14-8-25.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Geometry)

// 视图bounds的宽度
- (CGFloat)width;

// 视图bounds的高度
- (CGFloat)height;

// 视图的frame原点的x分量
- (CGFloat)left;

// 视图的frame原点的y分量
- (CGFloat)top;

// 设置视图的frame原点的x分量
- (void)setLeft:(CGFloat)x;

// 设置视图的frame原点的y分量
- (void)setTop:(CGFloat)x;

@end
