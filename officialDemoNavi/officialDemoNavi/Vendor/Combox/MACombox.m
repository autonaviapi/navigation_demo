//
//  MACombox.m
//  officialDemoNavi
//
//  Created by LiuX on 14-9-1.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "MACombox.h"
#import "UIView+Geometry.h"

@interface CustomButton:UIButton

- (CGRect)imageRectForContentRect:(CGRect)bounds;

@end

@implementation CustomButton

- (CGRect)imageRectForContentRect:(CGRect)bounds
{
    return CGRectMake(185, 10, 20, 20);
}

@end

@interface MACombox ()
{
    BOOL isOpened;
}

@property (nonatomic, strong) TableViewWithBlock *tb;

@property (strong, nonatomic) NSArray *selectItems;

@end

@implementation MACombox

- (id)initWithItems:(NSArray *)items
{
    self = [super init];
    if (self)
    {
        self.bounds = CGRectMake(0, 0, 200, 40);
        
        _selectItems = items;
        
        [self initInputTextField];
        
        [self initButton];
        
        [self initTableView];
    }
    return self;
}

- (void)initInputTextField
{
    self.inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.width, 20)];
    self.inputTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.inputTextField.font = [UIFont systemFontOfSize:14];
    self.inputTextField.enabled = NO;
    self.inputTextField.text = _selectItems[0];
    [self addSubview:_inputTextField];
}

- (void)initButton
{
    self.openButton = [CustomButton buttonWithType:UIButtonTypeCustom];
    _openButton.frame = CGRectMake(0, -10, self.width, 40);
   
    UIImage *openImage=[UIImage imageNamed:@"dropdown.png"];
    [_openButton setImage:openImage forState:UIControlStateNormal];
    
    [_openButton addTarget:self action:@selector(changeOpenStatus:)
          forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:_openButton];
}

- (void)initTableView
{
    __unsafe_unretained __typeof(self) unsafe_Self = self;
    self.tb = [[TableViewWithBlock alloc] initWithFrame:CGRectMake(5, 19.5, self.width - 10, 1)];
    
    [_tb initTableViewDataSourceAndDelegate:^(UITableView *tableView,NSInteger section) {
        return _selectItems.count;
        
    } setCellForIndexPathBlock:^(UITableView *tableView,NSIndexPath *indexPath){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectionCell"];
        if (!cell)
        {
             cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:@"SelectionCell"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        }
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        [cell.textLabel setText:_selectItems[indexPath.row]];
        CGFloat cellWidth = cell.bounds.size.width;
        cell.bounds = CGRectMake(0, 0, cellWidth, 25);
        return cell;
    } setDidSelectRowBlock:^(UITableView *tableView,NSIndexPath *indexPath){
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        _inputTextField.text = cell.textLabel.text;
        [_openButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        
        if (unsafe_Self.delegate && [unsafe_Self.delegate respondsToSelector:@selector(maCombox:didSelectItem:)]) {
            [unsafe_Self.delegate maCombox:unsafe_Self didSelectItem:cell.textLabel.text];
        }
    }];
    
    [_tb.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [_tb.layer setBorderWidth:1];
    _tb.layer.cornerRadius  = 5;
    _tb.layer.masksToBounds = YES;
    _tb.hidden = YES;
    [self addSubview:_tb];
}

- (IBAction)changeOpenStatus:(id)sender {
    
    if (isOpened) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(dropMenuWillHide:)]) {
           [self.delegate dropMenuWillHide:self];
        }
        [UIView animateWithDuration:0.3 animations:^{
            UIImage *closeImage = [UIImage imageNamed:@"dropdown.png"];
            [_openButton setImage:closeImage forState:UIControlStateNormal];
            
            CGRect frame = _tb.frame;
            
            frame.size.height = 1;
            [_tb setFrame:frame];
            _tb.hidden = YES;
            
        } completion:^(BOOL finished){
            isOpened = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(dropMenuDidHide:)]) {
                [self.delegate dropMenuDidHide:self];
            }
        }];
    }else{
        if (self.delegate && [self.delegate respondsToSelector:@selector(dropMenuWillShow:)]) {
            [self.delegate dropMenuWillShow:self];
        }
        [UIView animateWithDuration:0.3 animations:^{
            UIImage *openImage = [UIImage imageNamed:@"dropup.png"];
            [_openButton setImage:openImage forState:UIControlStateNormal];
            
            CGRect frame = _tb.frame;
            frame.size.height = 25 * _selectItems.count;
            [_tb setFrame:frame];
            _tb.hidden = NO;
        } completion:^(BOOL finished){
            isOpened = YES;
            if (self.delegate && [self.delegate respondsToSelector:@selector(dropMenuDidShow:)]) {
                [self.delegate dropMenuDidShow:self];
            }
        }];
    }
}

- (void)hideDropMenu
{
    if (isOpened)
    {
        [_openButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - Override Methods

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect tbFrame = _tb.frame;
    
    if (CGRectContainsPoint(tbFrame, point))
    {
        return _tb;
    }
    return [super hitTest:point withEvent:event];
}

@end
