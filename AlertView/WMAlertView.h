//
//  WMAlertView.h
//  WMAlertView
//
//  Created by Will on 2017/4/26.
//  Copyright © 2017年 iwm. All rights reserved.
//

#import <UIKit/UIKit.h>

//底部按钮样式
typedef NS_ENUM(NSUInteger, WMAlertViewButtonStyle) {
    KWMAlertViewButtonStyleDefault = 0,
    WMAlertViewButtonStyleBlue,
    WMAlertViewButtonStyleRed,
};


@class WMAlertView;
@protocol WMAlertViewDelegate <NSObject>
- (void)WMAlertView:(WMAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end


@interface WMAlertView : UIView

//是否开启MotionEffects 默认开启
@property (nonatomic, assign) BOOL openMotionEffects;
//点击背景 是否关闭当前对话 默认关闭
@property (nonatomic, assign) BOOL closeOnTouchUpOutside;
//容器View  自定义的View添加到这里面
@property (nonatomic, strong, readonly) UIView *containerView;


/**
 生成AlertView

 @param titleString titleStr
 @param containerView 自定义View 显示在title与按钮之间
 @param buttonTitles 按钮标题
 @param buttonStyles 按钮样式 与按钮标题意义对应
 @param delegate delegate
 */
- (instancetype)initWithTitleString:(NSString *)titleString containerView:(UIView *)containerView buttonTitles:(NSArray <__kindof NSString *>*)buttonTitles buttonStyles:(NSArray <__kindof NSNumber *>*)buttonStyles delegate:(id<WMAlertViewDelegate>)delegate;

- (void)show;
- (void)dismiss;

- (void)regsiterContainerViewWithNibName:(NSString *)nibName;

- (void)setButtonPressedAction:(void (^)(WMAlertView *alertView, NSInteger buttonIndex))onButtonPressed;

@end
