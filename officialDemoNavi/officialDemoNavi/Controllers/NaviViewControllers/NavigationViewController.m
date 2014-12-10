//
//  ZongheShowViewController.m
//  officialDemoNavi
//
//  Created by LiuX on 14-9-1.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "NavigationViewController.h"
#import "NavPointAnnotation.h"
#import "MACombox.h"
#import "RouteShowViewController.h"

#define kSetingViewHeight 215

typedef NS_ENUM(NSInteger, MapSelectPointState)
{
    MapSelectPointStateNone = 0,
    MapSelectPointStateStartPoint, // 当前操作为选择起始点
    MapSelectPointStateWayPoint,   // 当前操作为选择途径点
    MapSelectPointStateEndPoint,   // 当前操作为选择终止点
};


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


@interface NavigationViewController () <AMapNaviViewControllerDelegate,
                                        MAComboxDelegate,
                                        UIGestureRecognizerDelegate>
{
    UILabel *_wayPointLabel;
    UILabel *_strategyLabel;
    
    MACombox *_startPointCombox;
    MACombox *_endPointCombox;
    MACombox *_wayPointCombox;
    MACombox *_strategyCombox;
    
    MapSelectPointState _selectPointState;
    NavigationTypes     _naviType;
    TravelTypes         _travelType;
    
    BOOL _startCurrLoc;   // 起始点使用当前位置？
    BOOL _hasCurrLoc;
    
    UITapGestureRecognizer *_mapViewTapGesture;
    
    NSDictionary *_strategyMap;
}

@property (nonatomic, strong) AMapNaviViewController *naviViewController;

@property (nonatomic, strong) NavPointAnnotation *beginAnnotation;
@property (nonatomic, strong) NavPointAnnotation *wayAnnotation;
@property (nonatomic, strong) NavPointAnnotation *endAnnotation;

@property (nonatomic, weak) RouteShowViewController *routeShowVC;

@end

@implementation NavigationViewController


#pragma mark - Life Cycle

- (id)init
{
    self = [super init];
    if (self)
    {
        [self initCalRouteStrategyMap];
        [self initTravelType];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initNaviViewController];
    
    [self configSettingViews];
    
    [self initGestureRecognizer];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configMapView];
    
    [self initSettingState];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // 去掉手势
    [self.mapView removeGestureRecognizer:_mapViewTapGesture];
}



#pragma mark - Utils

- (void)initCalRouteStrategyMap
{
    _strategyMap = @{@"速度优先"   : @0,
                     @"费用优先"   : @1,
                     @"距离优先"   : @2,
                     @"普通路优先"             : @3,
                     @"时间优先(躲避拥堵)"      : @4,
                     @"躲避拥堵且不走收费道路"   : @12};
}


- (void)initTravelType
{
    _travelType = TravelTypeCar;
}


- (void)configMapView
{
    [self.mapView setDelegate:self];
    
    [self.mapView setFrame:CGRectMake(0, kSetingViewHeight,
                                      self.view.bounds.size.width,
                                      self.view.bounds.size.height - kSetingViewHeight)];
    
    [self.view insertSubview:self.mapView atIndex:0];
    
    [self.mapView addGestureRecognizer:_mapViewTapGesture];
    
    _hasCurrLoc = NO;
    
    self.mapView.showsUserLocation = YES;
}


- (void)initNaviViewController
{
    if (_naviViewController == nil)
    {
        _naviViewController = [[AMapNaviViewController alloc] initWithMapView:self.mapView delegate:self];
    }
}


- (void)configSettingViews
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
    
    UILabel *startPointLabel = [self createTitleLabel:@"起   点"];
    startPointLabel.left     = 30;
    startPointLabel.top      = 50;
    [self.view addSubview:startPointLabel];
    
    _startPointCombox = [[MACombox alloc] initWithItems:@[@"", @"使用当前位置", @"地图选点"]];
    _startPointCombox.delegate = self;
    _startPointCombox.left     = 90;
    _startPointCombox.top      = 50;
    [self.view insertSubview:_startPointCombox atIndex:0];
    
    
    UILabel *endPointLabel = [self createTitleLabel:@"终   点"];
    endPointLabel.left     = 30;
    endPointLabel.top      = 80;
    [self.view addSubview:endPointLabel];
    
    
    _endPointCombox = [[MACombox alloc] initWithItems:@[@"", @"地图选点"]];
    _endPointCombox.delegate = self;
    _endPointCombox.left     = 90;
    _endPointCombox.top      = 80;
    [self.view insertSubview:_endPointCombox atIndex:0];
    
    UILabel *wayPointLabel = [self createTitleLabel:@"途径点"];
    wayPointLabel.left     = 30;
    wayPointLabel.top      = 110;
    [self.view addSubview:wayPointLabel];
    
    _wayPointLabel = wayPointLabel;
    
    _wayPointCombox = [[MACombox alloc] initWithItems:@[@"", @"地图选点"]];
    _wayPointCombox.delegate = self;
    _wayPointCombox.left     = 90;
    _wayPointCombox.top      = 110;
    [self.view insertSubview:_wayPointCombox atIndex:0];
    
    UILabel *strategyLabel = [self createTitleLabel:@"策   略"];
    strategyLabel.left = 30;
    strategyLabel.top  = 140;
    [self.view addSubview:strategyLabel];
    
    _strategyLabel = strategyLabel;
    
    _strategyCombox = [[MACombox alloc] initWithItems:_strategyMap.allKeys];
    _strategyCombox.delegate = self;
    _strategyCombox.left     = 90;
    _strategyCombox.top      = 140;
    [self.view insertSubview:_strategyCombox atIndex:0];
    
    UIButton *routeBtn = [self createToolButton];
    [routeBtn setTitle:@"路径规划" forState:UIControlStateNormal];
    [routeBtn addTarget:self action:@selector(gpsNavi:) forControlEvents:UIControlEventTouchUpInside];
    routeBtn.left = 60;
    routeBtn.top  = 175;
    [self.view addSubview:routeBtn];
    
    UIButton *simuBtn = [self createToolButton];
    [simuBtn setTitle:@"模拟导航" forState:UIControlStateNormal];
    [simuBtn addTarget:self action:@selector(simulatorNavi:) forControlEvents:UIControlEventTouchUpInside];
    simuBtn.left = 190;
    simuBtn.top  = 175;
    [self.view addSubview:simuBtn];
}


- (void)initGestureRecognizer
{
    _mapViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(handleSingleTap:)];
}


- (UILabel *)createTitleLabel:(NSString *)title
{
    UILabel *titleLabel = [[UILabel alloc] init];
    
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font          = [UIFont systemFontOfSize:15];
    titleLabel.text          = title;
    [titleLabel sizeToFit];
    
    return titleLabel;
}


- (UIButton *)createToolButton
{
    UIButton *toolBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    
    toolBtn.layer.borderColor  = [UIColor lightGrayColor].CGColor;
    toolBtn.layer.borderWidth  = 0.5;
    toolBtn.layer.cornerRadius = 5;
    
    [toolBtn setBounds:CGRectMake(0, 0, 70, 30)];
    [toolBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    toolBtn.titleLabel.font = [UIFont systemFontOfSize: 13.0];
    
    return toolBtn;
}


- (void)initSettingState
{
    _startPointCombox.inputTextField.text = @"";
    _wayPointCombox.inputTextField.text   = @"";
    _endPointCombox.inputTextField.text   = @"";
    
    _beginAnnotation = nil;
    _wayAnnotation   = nil;
    _endAnnotation   = nil;
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    _selectPointState = MapSelectPointStateNone;
    _naviType = NavigationTypeNone;
}



#pragma mark - Gesture Action

- (void)handleSingleTap:(UITapGestureRecognizer *)theSingleTap
{
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:[theSingleTap locationInView:self.mapView]
                                              toCoordinateFromView:self.mapView];
    
    if (_selectPointState == MapSelectPointStateStartPoint)
    {
        if (_beginAnnotation)
        {
            _beginAnnotation.coordinate = coordinate;
        }
        else
        {
            _beginAnnotation = [[NavPointAnnotation alloc] init];
            [_beginAnnotation setCoordinate:coordinate];
            _beginAnnotation.title        = @"起始点";
            _beginAnnotation.navPointType = NavPointAnnotationStart;
            [self.mapView addAnnotation:_beginAnnotation];
        }
    }
    else if (_selectPointState == MapSelectPointStateWayPoint)
    {
        if (_wayAnnotation)
        {
            _wayAnnotation.coordinate = coordinate;
        }
        else
        {
            _wayAnnotation = [[NavPointAnnotation alloc] init];
            [_wayAnnotation setCoordinate:coordinate];
            _wayAnnotation.title        = @"途径点";
            _wayAnnotation.navPointType = NavPointAnnotationWay;
            [self.mapView addAnnotation:_wayAnnotation];
        }
    }
    else if (_selectPointState == MapSelectPointStateEndPoint)
    {
        if (_endAnnotation)
        {
            _endAnnotation.coordinate = coordinate;
        }
        else
        {
            _endAnnotation = [[NavPointAnnotation alloc] init];
            [_endAnnotation setCoordinate:coordinate];
            _endAnnotation.title        = @"终 点";
            _endAnnotation.navPointType = NavPointAnnotationEnd;
            [self.mapView addAnnotation:_endAnnotation];
        }
    }
}


#pragma mark - Button Actions

- (void)simulatorNavi:(id)sender
{
    _naviType = NavigationTypeSimulator;
    
    [self calRoute];
}


- (void)gpsNavi:(id)sender
{
    _naviType = NavigationTypeGPS;
    
    [self calRoute];
}


- (void)calRoute
{
    NSArray *startPoints;
    NSArray *wayPoints;
    NSArray *endPoints;
    
    if (_wayAnnotation)
    {
        wayPoints = @[[AMapNaviPoint locationWithLatitude:_wayAnnotation.coordinate.latitude
                                                longitude:_wayAnnotation.coordinate.longitude]];
    }
    
    if (_endAnnotation)
    {
        endPoints = @[[AMapNaviPoint locationWithLatitude:_endAnnotation.coordinate.latitude
                                                longitude:_endAnnotation.coordinate.longitude]];
    }
    
    if (_beginAnnotation)
    {
        startPoints = @[[AMapNaviPoint locationWithLatitude:_beginAnnotation.coordinate.latitude
                                                  longitude:_beginAnnotation.coordinate.longitude]];
    }
    
    if (_startCurrLoc)
    {
        if (endPoints.count > 0)
        {
            if (_travelType == TravelTypeCar)
            {
                [self.naviManager calculateDriveRouteWithEndPoints:endPoints
                                                         wayPoints:wayPoints
                                                   drivingStrategy:[_strategyMap[_strategyCombox.inputTextField.text] integerValue]];
            }
            else if (_travelType == TravelTypeWalk)
            {
                [self.naviManager calculateWalkRouteWithEndPoints:endPoints];
            }
            return;
        }
    }
    else
    {
        if (startPoints.count > 0 && endPoints.count > 0)
        {
            if (_travelType == TravelTypeCar)
            {
                [self.naviManager calculateDriveRouteWithStartPoints:startPoints
                                                           endPoints:endPoints
                                                           wayPoints:wayPoints
                                                     drivingStrategy:[_strategyMap[_strategyCombox.inputTextField.text] integerValue]];
            }
            else if (_travelType == TravelTypeWalk)
            {
                [self.naviManager calculateWalkRouteWithStartPoints:startPoints endPoints:endPoints];
            }
            
            return;
        }
    }
    [self.view makeToast:@"请先在地图上选点"
                duration:2.0
                position:[NSValue valueWithCGPoint:CGPointMake(160, 240)]];

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
        else if (navAnnotation.navPointType == NavPointAnnotationWay)
        {
            [pointAnnotationView setPinColor:MAPinAnnotationColorPurple];
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
        polylineView.lineWidth = 5.0f;
        polylineView.strokeColor = [UIColor redColor];
        
        return polylineView;
    }
    return nil;
}


- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    // 第一次定位时才将定位点显示在地图中心
    if (!_hasCurrLoc)
    {
        _hasCurrLoc = YES;
        
        [self.mapView setCenterCoordinate:userLocation.coordinate];
        [self.mapView setZoomLevel:12 animated:NO];
    }
}


#pragma mark - AMapNaviManager Delegate

- (void)AMapNaviManager:(AMapNaviManager *)naviManager didPresentNaviViewController:(UIViewController *)naviViewController
{
    [super AMapNaviManager:naviManager didPresentNaviViewController:naviViewController];
    
    // 初始化语音引擎
    [self initIFlySpeech];
    
    if (_naviType == NavigationTypeGPS)
    {
        [self.naviManager startGPSNavi];
    }
    else if (_naviType == NavigationTypeSimulator)
    {
        [self.naviManager startEmulatorNavi];
    }
}


- (void)AMapNaviManagerOnCalculateRouteSuccess:(AMapNaviManager *)naviManager
{
    [super AMapNaviManagerOnCalculateRouteSuccess:naviManager];
    
    if (_naviType == NavigationTypeGPS)
    {
        // 如果_routeShowVC不为nil，说明是偏航重算导致的算路，什么也不做
        if (!_routeShowVC)
        {
            RouteShowViewController *routeShowVC = [[RouteShowViewController alloc] initWithNavManager:naviManager
                                                                naviController:_naviViewController
                                                                       mapView:self.mapView];
            self.routeShowVC = routeShowVC;
            
            routeShowVC.title = @"线路展示";
            
            [self.navigationController pushViewController:routeShowVC animated:YES];
        }
    }
    else if (_naviType == NavigationTypeSimulator)
    {
        [self.naviManager presentNaviViewController:self.naviViewController animated:YES];
    }
}


- (void)AMapNaviManager:(AMapNaviManager *)naviManager onCalculateRouteFailure:(NSError *)error
{
    [super AMapNaviManager:naviManager onCalculateRouteFailure:error];
}



#pragma mark - AManNaviViewController Delegate

- (void)AMapNaviViewControllerCloseButtonClicked:(AMapNaviViewController *)naviViewController
{
    [self.iFlySpeechSynthesizer stopSpeaking];
    
    self.iFlySpeechSynthesizer.delegate = nil;
    self.iFlySpeechSynthesizer          = nil;
    
    [self.naviManager stopNavi];
    [self.naviManager dismissNaviViewControllerAnimated:YES];
    
    if (_naviType == NavigationTypeGPS)
    {
        [self.mapView setDelegate:self];
        
        [_routeShowVC configMapView];
    }
    else
    {
        [self configMapView];
        
        [self initSettingState];
    }
}


- (void)AMapNaviViewControllerMoreButtonClicked:(AMapNaviViewController *)naviViewController
{
    if (self.naviViewController.viewShowMode == AMapNaviViewShowModeCarNorthDirection)
    {
        self.naviViewController.viewShowMode = AMapNaviViewShowModeMapNorthDirection;
    }
    else
    {
        self.naviViewController.viewShowMode = AMapNaviViewShowModeCarNorthDirection;
    }
}


- (void)AMapNaviViewControllerTrunIndicatorViewTapped:(AMapNaviViewController *)naviViewController
{
    [self.naviManager readNaviInfoManual];
}


#pragma mark - MACombox Delegate

- (void)dropMenuWillHide:(MACombox *)combox
{
    [self.view sendSubviewToBack:combox];
}


- (void)dropMenuWillShow:(MACombox *)combox
{
    [self.view bringSubviewToFront:combox];
    
    [_startPointCombox hideDropMenu];
    [_endPointCombox   hideDropMenu];
    [_wayPointCombox   hideDropMenu];
    [_strategyCombox   hideDropMenu];
}


- (void)maCombox:(MACombox *)macombox didSelectItem:(NSString *)item
{
    if (macombox == _startPointCombox)
    {
        if ([item isEqualToString:@"地图选点"])
        {
            _selectPointState = MapSelectPointStateStartPoint;
            
            _wayPointCombox.inputTextField.text = @"";
            _endPointCombox.inputTextField.text = @"";
            
            _startCurrLoc = NO;
        }
        else if ([item isEqualToString:@"使用当前位置"])
        {
            if (_beginAnnotation)
            {
                [self.mapView removeAnnotation:_beginAnnotation];
                _beginAnnotation = nil;
            }
            _startCurrLoc = YES;
            if (_selectPointState == MapSelectPointStateStartPoint)
            {
                _selectPointState = MapSelectPointStateNone;
            }
        }
        else
        {
            _startCurrLoc = NO;
            if (_selectPointState == MapSelectPointStateStartPoint)
            {
                _selectPointState = MapSelectPointStateNone;
            }
        }
    }
    else if (macombox == _wayPointCombox)
    {
        if ([item isEqualToString:@"地图选点"])
        {
            _selectPointState = MapSelectPointStateWayPoint;
            
            if (!_startCurrLoc) _startPointCombox.inputTextField.text = @"";
            _endPointCombox.inputTextField.text = @"";
        }
        else
        {
            if (_selectPointState == MapSelectPointStateWayPoint)
            {
                _selectPointState = MapSelectPointStateNone;
            }
        }
    }
    else if (macombox == _endPointCombox)
    {
        if ([item isEqualToString:@"地图选点"])
        {
            _selectPointState = MapSelectPointStateEndPoint;
            
            if (!_startCurrLoc) _startPointCombox.inputTextField.text = @"";
            _wayPointCombox.inputTextField.text = @"";
        }
        else
        {
            if (_selectPointState == MapSelectPointStateEndPoint)
            {
                _selectPointState = MapSelectPointStateNone;
            }
        }
    }
}


#pragma mark - SegCtrl Event

- (IBAction)segCtrlClick:(id)sender
{
    UISegmentedControl *segCtrl = (UISegmentedControl *)sender;
    
    TravelTypes travelType = segCtrl.selectedSegmentIndex == 0 ? TravelTypeCar : TravelTypeWalk;
    
    if (travelType != _travelType)
    {
        _travelType = travelType;
        
        [self initSettingState];
        
        if (_travelType == TravelTypeWalk)
        {
            _wayPointCombox.userInteractionEnabled = NO;
            _strategyCombox.userInteractionEnabled = NO;
            
            [_wayPointCombox setAlpha:0.3];
            [_strategyCombox setAlpha:0.3];
            
            [_wayPointLabel setAlpha:0.3];
            [_strategyLabel setAlpha:0.3];
        }
        else
        {
            _wayPointCombox.userInteractionEnabled = YES;
            _strategyCombox.userInteractionEnabled = YES;
            
            [_wayPointCombox setAlpha:1];
            [_strategyCombox setAlpha:1];
            
            [_wayPointLabel setAlpha:1];
            [_strategyLabel setAlpha:1];
        }
    }
}

@end
