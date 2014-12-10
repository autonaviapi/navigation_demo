//
//  RoutePlanViewController.m
//  officialDemoNavi
//
//  Created by LiuX on 14-9-1.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "RoutePlanViewController.h"
#import "NavPointAnnotation.h"

#define kSetingViewHeight   150.f

typedef NS_ENUM(NSInteger, NavigationTypes)
{
    NavigationTypeNone = 0,
    NavigationTypeSimulator, // 模拟导航
    NavigationTypeGPS,       // 实时导航
};

typedef NS_ENUM(NSInteger, TravelTypes)
{
    TravelTypeCar = 0,    // 驾车方式
    TravelTypeWalk,       // 步行方式
};

@interface RoutePlanViewController ()<AMapNaviViewControllerDelegate>

@property (nonatomic, strong) AMapNaviPoint* startPoint;
@property (nonatomic, strong) AMapNaviPoint* endPoint;

@property (nonatomic, strong) NSArray *annotations;

@property (nonatomic, strong) MAPolyline *polyline;

@property (nonatomic) BOOL calRouteSuccess; // 指示是否算路成功

@property (nonatomic) NavigationTypes naviType;
@property (nonatomic) TravelTypes travelType;

@end

@implementation RoutePlanViewController

#pragma mark - Life Cycle

- (id)init
{
    self = [super init];
    if (self)
    {
        [self initNaviPoints];
        
        [self initAnnotations];
        
        // 初始化travel方式为驾车方式
        self.travelType = TravelTypeCar;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self configSubViews];
    
    [self configMapView];
}


- (void)configMapView
{
    [self.mapView setDelegate:self];
    [self.mapView setFrame:CGRectMake(0, kSetingViewHeight,
                                      self.view.bounds.size.width,
                                      self.view.bounds.size.height - kSetingViewHeight)];
    [self.view insertSubview:self.mapView atIndex:0];
    
    if (_calRouteSuccess)
    {
        [self.mapView addOverlay:_polyline];
    }
    
    if (self.annotations.count > 0)
    {
        [self.mapView addAnnotations:self.annotations];
    }
}



#pragma mark - Construct and Inits

- (void)initNaviPoints
{
    _startPoint = [AMapNaviPoint locationWithLatitude:39.989614 longitude:116.481763];
    _endPoint   = [AMapNaviPoint locationWithLatitude:39.983456 longitude:116.315495];
}


- (void)initAnnotations
{
    NavPointAnnotation *beginAnnotation = [[NavPointAnnotation alloc] init];
    
    [beginAnnotation setCoordinate:CLLocationCoordinate2DMake(_startPoint.latitude, _startPoint.longitude)];
    beginAnnotation.title        = @"起始点";
    beginAnnotation.navPointType = NavPointAnnotationStart;
    
    NavPointAnnotation *endAnnotation = [[NavPointAnnotation alloc] init];
    
    [endAnnotation setCoordinate:CLLocationCoordinate2DMake(_endPoint.latitude, _endPoint.longitude)];
    
    endAnnotation.title        = @"终点";
    endAnnotation.navPointType = NavPointAnnotationEnd;
    
    self.annotations = @[beginAnnotation, endAnnotation];
}


- (void)configSubViews
{
    UISegmentedControl *segCtrl = [[UISegmentedControl alloc] initWithItems:@[@"驾车" , @"步行"]];
    
    segCtrl.tintColor = [UIColor grayColor];
    [segCtrl setBounds:CGRectMake (0 ,0 ,180 ,30)];
    [segCtrl addTarget:self action:@selector(segCtrlClick:) forControlEvents:UIControlEventValueChanged];
    [segCtrl setTitleTextAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:17]}
                           forState:UIControlStateNormal];
    
    segCtrl.left                 = (self.view.width - 180) / 2;
    segCtrl.top                  = 10;
    segCtrl.selectedSegmentIndex = 0;
    [self.view addSubview:segCtrl];
    
    UILabel *startPointLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 45, 320, 20)];
    
    startPointLabel.textAlignment = NSTextAlignmentCenter;
    startPointLabel.font          = [UIFont systemFontOfSize:14];
    startPointLabel.text          = [NSString stringWithFormat:@"起 点：%f, %f", _startPoint.latitude, _startPoint.longitude];
    
    [self.view addSubview:startPointLabel];
    
    UILabel *endPointLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 75, 320, 20)];
    
    endPointLabel.textAlignment = NSTextAlignmentCenter;
    endPointLabel.font          = [UIFont systemFontOfSize:14];
    endPointLabel.text          = [NSString stringWithFormat:@"终 点：%f, %f", _endPoint.latitude, _endPoint.longitude];
    
    [self.view addSubview:endPointLabel];
    
    UIButton *routeBtn = [self createToolButton];
    [routeBtn setTitle:@"路径规划" forState:UIControlStateNormal];
    [routeBtn addTarget:self action:@selector(routeCal:) forControlEvents:UIControlEventTouchUpInside];
    routeBtn.left = 60;
    routeBtn.top  = 100;
    [self.view addSubview:routeBtn];
    
    UIButton *simuBtn = [self createToolButton];
    [simuBtn setTitle:@"模拟导航" forState:UIControlStateNormal];
    [simuBtn addTarget:self action:@selector(simulatorNavi:) forControlEvents:UIControlEventTouchUpInside];
    simuBtn.left = 130;
    simuBtn.top  = 100;
    [self.view addSubview:simuBtn];
    
    UIButton *gpsBtn = [self createToolButton];
    [gpsBtn setTitle:@"实时导航" forState:UIControlStateNormal];
    [gpsBtn addTarget:self action:@selector(gpsNavi:) forControlEvents:UIControlEventTouchUpInside];
    gpsBtn.left = 200;
    gpsBtn.top  = 100;
    [self.view addSubview:gpsBtn];
}


#pragma mark - Utils Methods

- (UIButton *)createToolButton
{
    UIButton *toolBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    toolBtn.layer.borderColor  = [UIColor lightGrayColor].CGColor;
    toolBtn.layer.borderWidth  = 0.5;
    toolBtn.layer.cornerRadius = 5;
    
    [toolBtn setBounds:CGRectMake(0, 0, 60, 30)];
    [toolBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    toolBtn.titleLabel.font = [UIFont systemFontOfSize: 13.0];
    
    return toolBtn;
}


- (void)showRouteWithNaviRoute:(AMapNaviRoute *)naviRoute
{
    if (naviRoute == nil) return;
    
    // 清除旧的overlays
    if (_polyline)
    {
        [self.mapView removeOverlay:_polyline];
        self.polyline = nil;
    }
    
    NSUInteger coordianteCount = [naviRoute.routeCoordinates count];
    CLLocationCoordinate2D coordinates[coordianteCount];
    for (int i = 0; i < coordianteCount; i++)
    {
        AMapNaviPoint *aCoordinate = [naviRoute.routeCoordinates objectAtIndex:i];
        coordinates[i] = CLLocationCoordinate2DMake(aCoordinate.latitude, aCoordinate.longitude);
    }
    
    _polyline = [MAPolyline polylineWithCoordinates:coordinates count:coordianteCount];
    [self.mapView addOverlay:_polyline];
}


#pragma mark - Button Actions

- (void)routeCal:(id)sender
{
    NSArray *startPoints = @[_startPoint];
    NSArray *endPoints   = @[_endPoint];
    
    if (self.travelType == TravelTypeCar)
    {
        [self.naviManager calculateDriveRouteWithStartPoints:startPoints endPoints:endPoints wayPoints:nil drivingStrategy:0];
    }
    else
    {
        [self.naviManager calculateWalkRouteWithStartPoints:startPoints endPoints:endPoints];
    }
}


- (void)simulatorNavi:(id)sender
{
    if (_calRouteSuccess)
    {
        self.naviType = NavigationTypeSimulator;
        
        /**
         * 特别说明：因为导航sdk与demo中使用的是同一个地图，所以当进入导航界面（AMapNaviViewController）时，当前的地图
         * 状态（包括delegate属性、所有overlays、annotations等等）会被清除，所以在进入和退出导航界面时请根据自己的需要
         * 做好当前地图状态的保存和恢复工作。
         */
        
        AMapNaviViewController *naviViewController = [[AMapNaviViewController alloc]
                                                      initWithMapView:self.mapView delegate:self];
        [self.naviManager presentNaviViewController:naviViewController animated:YES];
    }
    else
    {
        [self.view makeToast:@"请先进行路线规划"
                    duration:2.0
                    position:[NSValue valueWithCGPoint:CGPointMake(160, 240)]];
    }
}


- (void)gpsNavi:(id)sender
{
    if (_calRouteSuccess)
    {
        self.naviType = NavigationTypeGPS;
        
        /**
         * 特别说明：因为导航sdk与demo中使用的是同一个地图，所以当进入导航界面（AMapNaviViewController）时，当前的地图
         * 状态（包括delegate属性、所有overlays、annotations等等）会被清除，所以在进入和退出导航界面时请根据自己的需要
         * 做好当前地图状态的保存和恢复工作。
         */
        
        AMapNaviViewController *naviViewController = [[AMapNaviViewController alloc]
                                                      initWithMapView:self.mapView delegate:self];
        
        [self.naviManager presentNaviViewController:naviViewController animated:YES];
    }
    else
    {
        [self.view makeToast:@"请先进行路线规划"
                    duration:2.0
                    position:[NSValue valueWithCGPoint:CGPointMake(160, 240)]];
    }
}




#pragma mark - AMapNaviManager Delegate

- (void)AMapNaviManager:(AMapNaviManager *)naviManager onCalculateRouteFailure:(NSError *)error
{
    [super AMapNaviManager:naviManager onCalculateRouteFailure:error];
}


- (void)AMapNaviManagerOnCalculateRouteSuccess:(AMapNaviManager *)naviManager
{
    [super AMapNaviManagerOnCalculateRouteSuccess:naviManager];
    
    [self showRouteWithNaviRoute:[[naviManager naviRoute] copy]];
    
    _calRouteSuccess = YES;
}


- (void)AMapNaviManager:(AMapNaviManager *)naviManager didPresentNaviViewController:(UIViewController *)naviViewController
{
    [super AMapNaviManager:naviManager didPresentNaviViewController:naviViewController];
    
    // 初始化语音引擎
    [self initIFlySpeech];
    
    if (self.naviType == NavigationTypeGPS)
    {
        [self.naviManager startGPSNavi];
    }
    else if (self.naviType == NavigationTypeSimulator)
    {
        [self.naviManager startEmulatorNavi];
    }
}


#pragma mark - AManNaviViewController Delegate

- (void)AMapNaviViewControllerCloseButtonClicked:(AMapNaviViewController *)naviViewController
{
    if (self.naviType == NavigationTypeGPS)
    {
        [self.iFlySpeechSynthesizer stopSpeaking];
        
        self.iFlySpeechSynthesizer.delegate = nil;
        self.iFlySpeechSynthesizer          = nil;
        
        [self.naviManager stopNavi];
    }
    else if (self.naviType == NavigationTypeSimulator)
    {
        [self.iFlySpeechSynthesizer stopSpeaking];
        
        self.iFlySpeechSynthesizer.delegate = nil;
        self.iFlySpeechSynthesizer          = nil;

        [self.naviManager stopNavi];
    }

    [self.naviManager dismissNaviViewControllerAnimated:YES];
    
    // 退出导航界面后恢复地图的状态
    [self configMapView];
}


- (void)AMapNaviViewControllerMoreButtonClicked:(AMapNaviViewController *)naviViewController
{
    if (naviViewController.viewShowMode == AMapNaviViewShowModeCarNorthDirection)
    {
        naviViewController.viewShowMode = AMapNaviViewShowModeMapNorthDirection;
    }
    else
    {
        naviViewController.viewShowMode = AMapNaviViewShowModeCarNorthDirection;
    }
}


- (void)AMapNaviViewControllerTrunIndicatorViewTapped:(AMapNaviViewController *)naviViewController
{
    [self.naviManager readNaviInfoManual];
}


#pragma mark - MAMapView Delegate

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[NavPointAnnotation class]])
    {
        static NSString *annotationIdentifier = @"annotationIdentifier";
        
        MAPinAnnotationView *pointAnnotationView = (MAPinAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if (pointAnnotationView == nil)
        {
            pointAnnotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation
                                                                  reuseIdentifier:annotationIdentifier];
        }
        
        pointAnnotationView.animatesDrop   = NO;
        pointAnnotationView.canShowCallout = NO;
        pointAnnotationView.draggable      = NO;
        
        NavPointAnnotation *navAnnotation = (NavPointAnnotation *)annotation;
        
        if (navAnnotation.navPointType == NavPointAnnotationStart)
        {
            [pointAnnotationView setPinColor:MAPinAnnotationColorGreen];
        }
        else if (navAnnotation.navPointType == NavPointAnnotationEnd)
        {
            [pointAnnotationView setPinColor:MAPinAnnotationColorRed];
        }
        return pointAnnotationView;
    }
    
    return nil;
}


- (MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineView *polylineView = [[MAPolylineView alloc] initWithPolyline:overlay];
        
        polylineView.lineWidth   = 5.0f;
        polylineView.strokeColor = [UIColor redColor];
        
        return polylineView;
    }
    return nil;
}


#pragma mark - SegCtrl Event

- (IBAction)segCtrlClick:(id)sender
{
    UISegmentedControl *segCtrl = (UISegmentedControl *)sender;
    
    TravelTypes travelType = segCtrl.selectedSegmentIndex == 0 ? TravelTypeCar : TravelTypeWalk;
    if (travelType != self.travelType)
    {
        self.travelType      = travelType;
        self.calRouteSuccess = NO;
        
        if (_polyline)
        {
            [self.mapView removeOverlay:_polyline];
            self.polyline = nil;
        }
    }
}

@end
