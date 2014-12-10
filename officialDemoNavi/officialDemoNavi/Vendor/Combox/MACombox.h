//
//  MACombox.h
//  officialDemoNavi
//
//  Created by LiuX on 14-9-1.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableViewWithBlock.h"

@class MACombox;

@protocol MAComboxDelegate <NSObject>

@optional

- (void)dropMenuWillShow:(MACombox *)combox;
- (void)dropMenuWillHide:(MACombox *)combox;

- (void)dropMenuDidShow:(MACombox *)combox;
- (void)dropMenuDidHide:(MACombox *)combox;

- (void)maCombox:(MACombox *)macombox didSelectItem:(NSString *)item;

@end

@interface MACombox : UIView

@property (nonatomic, strong) UITextField *inputTextField;
@property (nonatomic, strong) UIButton *openButton;
@property (nonatomic, assign) id <MAComboxDelegate> delegate;

- (id)initWithItems:(NSArray *)items;

- (void)hideDropMenu;

@end
