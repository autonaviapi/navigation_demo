//
//  HUDNaviViewController.m
//  officialDemoNavi
//
//  Created by LiuX on 14-9-1.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "HUDNaviViewController.h"

@interface HUDNaviViewController () <AMapNaviHUDViewControllerDelegate>

@property (nonatomic, strong) AMapNaviHUDViewController *naviViewController;

@property (nonatomic, strong) AMapNaviPoint* startPoint;
@property (nonatomic, strong) AMapNaviPoint* endPoint;

@end

@implementation HUDNaviViewController


#pragma mark - Life Cycle

- (id)init
{
    self = [super init];
    if (self)
    {
        _startPoint = [AMapNaviPoint locationWithLatitude:39.989614 longitude:116.481763];
        _endPoint   = [AMapNaviPoint locationWithLatitude:39.983456 longitude:116.315495];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initNaviViewController];
    [self configSubViews];
}


#pragma mark - Init &Constructs

- (void)initNaviViewController
{
    if (_naviViewController == nil)
    {
        _naviViewController = [[AMapNaviHUDViewController alloc] initWithDelegate:self];
    }
}


- (void)configSubViews
{
    UILabel *startPointLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, 320, 20)];
    
    startPointLabel.textAlignment = NSTextAlignmentCenter;
    startPointLabel.font = [UIFont systemFontOfSize:14];
    startPointLabel.text = [NSString stringWithFormat:@"起 点：%f, %f", _startPoint.latitude, _startPoint.longitude];
    
    [self.view addSubview:startPointLabel];
    
    UILabel *endPointLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 130, 320, 20)];
    
    endPointLabel.textAlignment = NSTextAlignmentCenter;
    endPointLabel.font = [UIFont systemFontOfSize:14];
    endPointLabel.text = [NSString stringWithFormat:@"终 点：%f, %f", _endPoint.latitude, _endPoint.longitude];
    
    [self.view addSubview:endPointLabel];
    
    UIButton *startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    startBtn.layer.borderColor  = [UIColor lightGrayColor].CGColor;
    startBtn.layer.borderWidth  = 0.5;
    startBtn.layer.cornerRadius = 5;
    
    [startBtn setFrame:CGRectMake(60, 160, 200, 30)];
    [startBtn setTitle:@"HUD显示" forState:UIControlStateNormal];
    [startBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    startBtn.titleLabel.font = [UIFont systemFontOfSize: 14.0];
    
    [startBtn addTarget:self action:@selector(startHUDNavi:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:startBtn];
}


#pragma mark - Button Actions

- (void)startHUDNavi:(id)sender
{
    // 算路
    [self calculateRoute];
}


- (void)calculateRoute
{
    NSArray *startPoints = @[_startPoint];
    NSArray *endPoints   = @[_endPoint];
    
    [self.naviManager calculateDriveRouteWithStartPoints:startPoints endPoints:endPoints wayPoints:nil drivingStrategy:0];
}



#pragma mark - AMapNaviManager Delegate

- (void)AMapNaviManager:(AMapNaviManager *)naviManager didPresentNaviViewController:(UIViewController *)naviViewController
{
    [super AMapNaviManager:naviManager didPresentNaviViewController:naviViewController];
    
    // 初始化语音引擎
    [self initIFlySpeech];
    
    [self.naviManager startEmulatorNavi];
}


- (void)AMapNaviManagerOnCalculateRouteSuccess:(AMapNaviManager *)naviManager
{
    [super AMapNaviManagerOnCalculateRouteSuccess:naviManager];
    
    [self.naviManager presentNaviViewController:self.naviViewController animated:YES];
}



#pragma mark - AMapNaviHUDViewControler Delegate

- (void)AMapNaviHUDViewControllerBackButtonClicked:(AMapNaviHUDViewController *)naviHUDViewController
{
    [self.iFlySpeechSynthesizer stopSpeaking];
    self.iFlySpeechSynthesizer.delegate = nil;
    self.iFlySpeechSynthesizer = nil;
    
    [self.naviManager stopNavi];
    [self.naviManager dismissNaviViewControllerAnimated:YES];
}

@end
