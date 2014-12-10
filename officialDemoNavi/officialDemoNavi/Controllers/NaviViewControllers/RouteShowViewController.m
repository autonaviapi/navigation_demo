//
//  MARouteShowViewController.m
//  officialDemoNavi
//
//  Created by LiuX on 14-9-2.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "RouteShowViewController.h"

#define kBottomPaneHeight 60.0

@interface RouteShowViewController ()

@property (nonatomic, strong) AMapNaviManager *actNaviManager;
@property (nonatomic, strong) AMapNaviViewController *naviViewController;

@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) UIView *bottomPanel;

@property (nonatomic, strong) NSArray *annotations;

@end

@implementation RouteShowViewController

- (id)initWithNavManager:(AMapNaviManager *)manager
          naviController:(AMapNaviViewController *)naviController mapView:(MAMapView *)mapView
{
    self = [super init];
    if (self)
    {
        self.actNaviManager     = manager;
        self.naviViewController = naviController;
        self.mapView            = mapView;
        self.annotations        = mapView.annotations;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initTitle:self.title];
    
    [self initBaseNavigationBar];
    
    [self configMapView];
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self configBottomPanel];
}



#pragma mark - Utils

- (void)configBottomPanel
{
    [_bottomPanel removeFromSuperview];
    
    _bottomPanel = [[UIView alloc] initWithFrame:
                    CGRectMake(0, self.view.height - kBottomPaneHeight, self.view.width, kBottomPaneHeight)];
    
    UILabel *titlabel = [self createTitleLabel:[NSString stringWithFormat: @"全程：%.2f公里 / %d分钟",
                                                _actNaviManager.naviRoute.routeLength / 1000.0, _actNaviManager.naviRoute.routeTime / 60]];
    titlabel.frame = CGRectMake(20, 10, titlabel.width, titlabel.height);
    [_bottomPanel addSubview:titlabel];
    
    titlabel = [self createTitleLabel:[NSString stringWithFormat: @"收费：%d元",
                                       _actNaviManager.naviRoute.routeTollCost]];
    titlabel.frame = CGRectMake(20, 35, titlabel.width, titlabel.height);
    [_bottomPanel addSubview:titlabel];
    
    UIButton *routeBtn = [self createToolButton];
    [routeBtn setTitle:@"实时导航" forState:UIControlStateNormal];
    [routeBtn addTarget:self action:@selector(gpsNavi:) forControlEvents:UIControlEventTouchUpInside];
    routeBtn.center = CGPointMake(260, kBottomPaneHeight / 2.0);
    [_bottomPanel addSubview:routeBtn];
    
    [self.view addSubview:_bottomPanel];
}


- (void)configMapView
{
    [self.mapView setFrame:CGRectMake(0, 0, self.view.width, self.view.height - kBottomPaneHeight)];
    [self.view insertSubview:self.mapView atIndex:0];
    
    [self.mapView addAnnotations:_annotations];
    [self showRouteWithNaviRoute:_actNaviManager.naviRoute];
}

- (void)showRouteWithNaviRoute:(AMapNaviRoute *)naviRoute
{
    if (naviRoute == nil)
    {
        return;
    }
    
    [self.mapView removeOverlays:self.mapView.overlays];
    
    NSUInteger coordianteCount = [naviRoute.routeCoordinates count];
    CLLocationCoordinate2D coordinates[coordianteCount];
    for (int i = 0; i < coordianteCount; i++)
    {
        AMapNaviPoint *aCoordinate = [naviRoute.routeCoordinates objectAtIndex:i];
        coordinates[i] = CLLocationCoordinate2DMake(aCoordinate.latitude, aCoordinate.longitude);
    }
    
    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coordinates count:coordianteCount];
    [self.mapView addOverlay:polyline];
    [self.mapView setVisibleMapRect:[polyline boundingMapRect] animated:NO];
}



#pragma mark - GPS navi

- (void)gpsNavi:(id)sender
{
    [self.actNaviManager presentNaviViewController:self.naviViewController animated:YES];
}


#pragma mark - Utils

- (UILabel *)createTitleLabel:(NSString *)title
{
    UILabel *titleLabel = [[UILabel alloc] init];
    
    titleLabel.textAlignment = NSTextAlignmentLeft;
    titleLabel.font = [UIFont systemFontOfSize:14];
    titleLabel.text = title;
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



#pragma mark - Utility

- (void)clearMapView
{
    self.mapView.showsUserLocation = NO;
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    [self.mapView removeOverlays:self.mapView.overlays];
    
    self.mapView.delegate = nil;
}

#pragma mark - Handle Action

- (void)returnAction
{
    [self.navigationController popViewControllerAnimated:YES];
    
    [self clearMapView];
}

#pragma mark - Initialization

- (void)initBaseNavigationBar
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(returnAction)];
}

- (void)initTitle:(NSString *)title
{
    UILabel *titleLabel = [[UILabel alloc] init];
    
    titleLabel.backgroundColor  = [UIColor clearColor];
    titleLabel.textColor        = [UIColor whiteColor];
    titleLabel.text             = title;
    [titleLabel sizeToFit];
    
    self.navigationItem.titleView = titleLabel;
}


@end
