//
//  AMapNaviInfo.h
//  AMapNaviKit
//
//  Created by 刘博 on 14-8-22.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "AMapNaviCommonObj.h"

/*!
 @brief 导航过程中的导航信息
 */
@interface AMapNaviInfo : NSObject

/*!
 @brief 离终点剩余距离,单位米
 */
@property (nonatomic, assign) NSInteger routeRemainDistance;

/*!
 @brief 离终点预估剩余时间,单位秒
 */
@property (nonatomic, assign) NSInteger routeRemainTime;

@end
