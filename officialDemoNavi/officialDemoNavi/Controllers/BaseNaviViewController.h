//
//  BaseNaviViewController.h
//  officialDemoNavi
//
//  Created by 刘博 on 14-7-24.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AMapNaviKit/MAMapKit.h>
#import <AMapNaviKit/AMapNaviKit.h>
#import "Toast+UIView.h"
#import "UIView+Geometry.h"
#import "iflyMSC/IFlySpeechSynthesizer.h"
#import "iflyMSC/IFlySpeechSynthesizerDelegate.h"
#import "iflyMSC/IFlySpeechConstant.h"
#import "iflyMSC/IFlySpeechUtility.h"
#import "iflyMSC/IFlySetting.h"

@interface BaseNaviViewController : UIViewController <MAMapViewDelegate,
                                                      AMapNaviManagerDelegate,
                                                      IFlySpeechSynthesizerDelegate>

@property (nonatomic, strong) MAMapView *mapView;

@property (nonatomic, strong) IFlySpeechSynthesizer *iFlySpeechSynthesizer;

@property (nonatomic, strong) AMapNaviManager *naviManager;

- (void)returnAction;

- (void)initIFlySpeech;

@end
