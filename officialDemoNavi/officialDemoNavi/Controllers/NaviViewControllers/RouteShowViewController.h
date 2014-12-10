//
//  MARouteShowViewController.h
//  officialDemoNavi
//
//  Created by LiuX on 14-9-2.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMapNaviKit/MAMapKit.h>
#import <AMapNaviKit/AMapNaviKit.h>
#import "Toast+UIView.h"
#import "UIView+Geometry.h"

@interface RouteShowViewController : UIViewController <MAMapViewDelegate>

- (id)initWithNavManager:(AMapNaviManager *)manager
          naviController:(AMapNaviViewController *)naviController mapView:(MAMapView *)mapView;

- (void)configMapView;

@end
