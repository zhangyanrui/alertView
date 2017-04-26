//
//  WMAlertView.m
//  WMAlertView
//
//  Created by Will on 2017/4/26.
//  Copyright © 2017年 iwm. All rights reserved.
//

#import "WMAlertView.h"
#import <QuartzCore/QuartzCore.h>

//title四个方向间距
const static CGFloat kWMAlertViewDefaultTitleSpacer        = 20;
//alert上下最小间距
const static CGFloat kWMAlertViewMinSpacerToWindowHeight   = 50;
//alert左右最小间距
const static CGFloat kWMAlertViewMinSpacerToWindowWidth   = 10;

//button间距
static const CGFloat kWMAlertViewButtonHorizontalSpace =  10;

//Button默认宽
const static CGFloat kWMAlertViewDefaultButtonHeight       = 50;
//button与contentView的间距
const static CGFloat kWMAlertViewDefaultButtonSpacerHeight = 1;
//alertView圆角
const static CGFloat kWMAlertViewCornerRadius              = 5.f;
//alertView MotionEffec
const static CGFloat kWMAlertMotionEffectExtent            = 30.0;

@interface WMAlertView() <WMAlertViewDelegate> {
    CGFloat _buttonHeight;
    CGFloat _buttonSpacerHeight;
}

//整体可见区域 包含containerView
@property (nonatomic, strong) UIView *dialogView;

@property (nonatomic, weak) id<WMAlertViewDelegate> delegate;
@property (nonatomic, copy) NSString *titleString;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, copy) NSArray *buttonTitles;
@property (nonatomic, copy) NSArray *buttonStyles;
//容器View  自定义的View添加到这里面
@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, copy) void (^onButtonPressed)(WMAlertView *alertView, NSInteger buttonIndex);

@end


@implementation WMAlertView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        
        _delegate = self;
        _openMotionEffects = YES;
        _closeOnTouchUpOutside = NO;
        _buttonHeight = 0;
        _buttonSpacerHeight = 0;
        _buttonTitles = @[@"关闭"];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

#pragma mark - Public Method

- (instancetype)initWithTitleString:(NSString *)titleString containerView:(UIView *)containerView buttonTitles:(NSArray <__kindof NSString *>*)buttonTitles buttonStyles:(NSArray <__kindof NSNumber *>*)buttonStyles delegate:(id<WMAlertViewDelegate>)delegate {
    self = [self init];
    if (self) {
        self.titleString = titleString;
        self.containerView = containerView;
        self.buttonTitles = buttonTitles;
        self.buttonStyles = buttonStyles;
        
        if (delegate) {
            self.delegate = delegate;
        }
        
    }
    return self;
}

- (void)setButtonPressedAction:(void (^)(WMAlertView *, NSInteger))onButtonPressed {
    self.onButtonPressed = onButtonPressed;
}

- (void)show {
    
    [self createContainerView];
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    
    if (_openMotionEffects) {
        [self addMotionEffects];
    }
    
    self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    
    [self addSubview:_dialogView];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (interfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
                self.transform = CGAffineTransformMakeRotation(M_PI * 270.0 / 180.0);
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                self.transform = CGAffineTransformMakeRotation(M_PI * 90.0 / 180.0);
                break;
                
            case UIInterfaceOrientationPortraitUpsideDown:
                self.transform = CGAffineTransformMakeRotation(M_PI * 180.0 / 180.0);
                break;
                
            default:
                break;
        }
        
        [self setFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        
    } else {
        
        CGSize screenSize = [self screenSize];
        CGSize dialogSize = [self dialogSize];
        CGSize keyboardSize = CGSizeMake(0, 0);
        
        self.dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - keyboardSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
        
    }
    
    [[[[UIApplication sharedApplication] windows] firstObject] addSubview:self];
    
    
    self.dialogView.layer.opacity = 0.5f;
    self.dialogView.layer.transform = CATransform3DMakeScale(1.3f, 1.3f, 1.0);
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f];
                         self.dialogView.layer.opacity = 1.0f;
                         self.dialogView.layer.transform = CATransform3DMakeScale(1, 1, 1);
                     }
                     completion:NULL
     ];
    
}



- (void)dismiss {
    CATransform3D currentTransform = self.dialogView.layer.transform;
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        CGFloat startRotation = [[self.dialogView valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
        CATransform3D rotation = CATransform3DMakeRotation(-startRotation + M_PI * 270.0 / 180.0, 0.0f, 0.0f, 0.0f);
        self.dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1, 1, 1));
    }
    
    self.dialogView.layer.opacity = 1.0f;
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f];
                         self.dialogView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6f, 0.6f, 1.0));
                         self.dialogView.layer.opacity = 0.0f;
                     }
                     completion:^(BOOL finished) {
                         for (UIView *v in [self subviews]) {
                             [v removeFromSuperview];
                         }
                         [self removeFromSuperview];
                     }
     ];
}


#pragma mark - Actions
//点击某个按钮
- (void)someoneButtonPressed:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(WMAlertView:clickedButtonAtIndex:)]) {
        [self.delegate WMAlertView:self clickedButtonAtIndex:[sender tag]];
    }
    
    if (self.onButtonPressed) {
        self.onButtonPressed(self, (int)[sender tag]);
    }
}

// 如果不设置delegate 默认回调此方法
- (void)WMAlertView:(WMAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"Button Clicked! %d, %d", (int)buttonIndex, (int)[alertView tag]);
    [self dismiss];
}

#pragma mark - Tools

- (UIImage *)imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


- (UIColor *)colorWithHexValue:(NSUInteger)hexValue {
    UIColor *color = nil;
    if ((hexValue >> 24) > 0) { //AARRGGBB
        color = [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0
                                green:((float)((hexValue & 0xFF00) >> 8))/255.0
                                 blue:((float)(hexValue & 0xFF))/255.0
                                alpha:((float)((hexValue & 0xFF000000) >> 24))/255.0];
    }
    else { //RRGGBB
        color = [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0
                                green:((float)((hexValue & 0xFF00) >> 8))/255.0
                                 blue:((float)(hexValue & 0xFF))/255.0
                                alpha:1.0];
    }
    return color;
}

- (CGFloat)suggestHeighForLabel:(UILabel *)aLabel {
    CGRect contentRect = [aLabel.text boundingRectWithSize:CGSizeMake(aLabel.frame.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: aLabel.font} context:nil];
    return contentRect.size.height;
}


- (void)createContainerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 0)];
    }
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(kWMAlertViewDefaultTitleSpacer, kWMAlertViewDefaultTitleSpacer, [self dialogSize].width - 2 * kWMAlertViewDefaultTitleSpacer, 0)];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [self colorWithHexValue:0x333333];
        _titleLabel.numberOfLines =  0;
    }
    _titleLabel.text = self.titleString;
    
    CGRect titleLabelFrame = self.titleLabel.frame;
    titleLabelFrame.origin.y = self.titleString.length > 0 ? kWMAlertViewDefaultTitleSpacer : 0;
    titleLabelFrame.size.height = self.titleString.length ? [self suggestHeighForLabel:self.titleLabel] : 0;
    self.titleLabel.frame = titleLabelFrame;
    
    
    CGSize screenSize = [self screenSize];
    CGSize dialogSize = [self dialogSize];
    
    self.frame = CGRectMake(0, 0, screenSize.width, screenSize.height);
    
    _dialogView = [[UIView alloc] initWithFrame:CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height)];
    _dialogView.clipsToBounds = YES;
    
    _dialogView.layer.cornerRadius = kWMAlertViewCornerRadius;
    _dialogView.backgroundColor = [UIColor whiteColor];
    
    [_dialogView addSubview:self.titleLabel];
    
    
    CGRect containerViewFrame = self.containerView.frame;
    containerViewFrame.origin.x = 0;
    containerViewFrame.origin.y = [self containerViewOrignY];
    
    if (containerViewFrame.size.width > [self screenSize].width - 2 * kWMAlertViewMinSpacerToWindowWidth) {
        containerViewFrame.size.width = [self screenSize].width - 2 * kWMAlertViewMinSpacerToWindowWidth;
    }
    self.containerView.frame = containerViewFrame;
    
    
    if ([self dialogSize].height == [self screenSize].height - 2*kWMAlertViewMinSpacerToWindowHeight) {
        CGFloat scrollViewHeigh = [self dialogSize].height - [self containerViewOrignY] - _buttonHeight - _buttonSpacerHeight;
        UIScrollView *aScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, containerViewFrame.origin.y, self.dialogView.frame.size.width, scrollViewHeigh)];
        
        CGSize aScrollViewContentSize = aScrollView.contentSize;
        aScrollViewContentSize.height = containerViewFrame.size.height;
        aScrollView.contentSize = aScrollViewContentSize;
        
        [aScrollView addSubview:self.containerView];
        [_dialogView addSubview:aScrollView];
        
        CGRect containerViewFrame = self.containerView.frame;
        containerViewFrame.origin.y = 0;
        self.containerView.frame = containerViewFrame;
        
    } else {
        [_dialogView addSubview:self.containerView];
    }
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, _dialogView.bounds.size.height - _buttonHeight - _buttonSpacerHeight, _dialogView.bounds.size.width, 0.5)];
    lineView.backgroundColor = [UIColor colorWithRed:198.0/255.0 green:198.0/255.0 blue:198.0/255.0 alpha:1.0f];
    [_dialogView addSubview:lineView];
    
    
    [self addButtonsToBottom];
    
    _dialogView.layer.shouldRasterize = YES;
    _dialogView.layer.rasterizationScale = [[UIScreen mainScreen] scale];
}

//生成按钮  并添加到container
- (void)addButtonsToBottom {
    if (!self.buttonTitles) { return; }
    
    BOOL onlyOneButton = self.buttonTitles.count == 1;
    
    CGFloat allButtonWidth = _dialogView.bounds.size.width - (2 + self.buttonTitles.count - 1) * kWMAlertViewButtonHorizontalSpace;
    CGFloat buttonWidth = allButtonWidth / self.buttonTitles.count;
    
    
    for (int i=0; i<[self.buttonTitles count]; i++) {
        
        WMAlertViewButtonStyle currentStyle = KWMAlertViewButtonStyleDefault;
        if (self.buttonStyles.count > i) {
            currentStyle = [self.buttonStyles[i] integerValue];
        }
        
        UIButton *aButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        
        if (onlyOneButton) {
            [aButton setFrame:CGRectMake(0, _dialogView.bounds.size.height - _buttonHeight, _dialogView.bounds.size.width, _buttonHeight)];
        } else {
            [aButton setFrame:CGRectMake(kWMAlertViewButtonHorizontalSpace + (kWMAlertViewButtonHorizontalSpace + buttonWidth) * i , _dialogView.bounds.size.height - _buttonHeight + 5, buttonWidth, _buttonHeight - 10)];
        }
        
        [aButton addTarget:self action:@selector(someoneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [aButton setTag:i];
        
        [aButton.titleLabel setFont:[UIFont boldSystemFontOfSize:16.0f]];
        [aButton setTitle:[self.buttonTitles objectAtIndex:i] forState:UIControlStateNormal];
        aButton.titleLabel.numberOfLines = 0;
        aButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [aButton.layer setCornerRadius:kWMAlertViewCornerRadius];
        aButton.clipsToBounds = !onlyOneButton;
        
        [_dialogView addSubview:aButton];
        
        //关联事件 外观
        switch (currentStyle) {
            
            case WMAlertViewButtonStyleRed:
                [aButton setBackgroundImage:[self imageFromColor:[self colorWithHexValue:0xff2d4b]] forState:UIControlStateNormal];
                [aButton setTitleColor:[self colorWithHexValue:0xffffff] forState:UIControlStateNormal];
                break;
            case WMAlertViewButtonStyleBlue:
                [aButton setBackgroundImage:[self imageFromColor:[self colorWithHexValue:0x228fea]] forState:UIControlStateNormal];
                [aButton setTitleColor:[self colorWithHexValue:0xffffff] forState:UIControlStateNormal];
                break;
                
            case KWMAlertViewButtonStyleDefault:
            default:
                if (!onlyOneButton) {
                    aButton.layer.borderColor = [[self colorWithHexValue:0xcccccc] CGColor];
                    aButton.layer.borderWidth = .5;
                }
                aButton.backgroundColor = self.dialogView.backgroundColor;
                [aButton setBackgroundImage:[self imageFromColor:[self colorWithHexValue:0xf2f2f2]] forState:UIControlStateHighlighted];
                [aButton setTitleColor:[self colorWithHexValue:0x333333] forState:UIControlStateNormal];
                break;
        }
    }
}

- (void)regsiterContainerViewWithNibName:(NSString *)nibName {
    if (!nibName || !nibName.length ) {
        return;
    }
    UIView *aView = [[[UINib nibWithNibName:nibName bundle:nil] instantiateWithOwner:self options:nil] firstObject];
    self.containerView = aView;
    
}

// 计算Dialog 大小
- (CGSize)dialogSize {
    
    CGFloat dialogWidth = self.containerView.frame.size.width;
    if (dialogWidth > [self screenSize].width - kWMAlertViewMinSpacerToWindowWidth * 2) {
        dialogWidth = [self screenSize].width - kWMAlertViewMinSpacerToWindowWidth * 2;
    }
    
    CGFloat dialogHeight = [self containerViewOrignY] + self.containerView.frame.size.height + _buttonHeight + _buttonSpacerHeight;
    
    if (dialogHeight > [self screenSize].height - 2*kWMAlertViewMinSpacerToWindowHeight) {
        dialogHeight =  [self screenSize].height - 2*kWMAlertViewMinSpacerToWindowHeight;
    }
    
    return CGSizeMake(dialogWidth, dialogHeight);
}

- (CGFloat)containerViewOrignY {
    CGFloat orignY = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height;
    if (self.titleString.length) {
        orignY += kWMAlertViewDefaultTitleSpacer;
    }
    return orignY;
}



// 动态计算屏幕长宽
- (CGSize)screenSize {
   
    if (self.buttonTitles!=NULL && [self.buttonTitles count] > 0) {
        _buttonHeight       = kWMAlertViewDefaultButtonHeight;
        _buttonSpacerHeight = kWMAlertViewDefaultButtonSpacerHeight;
    } else {
        _buttonHeight = 0;
        _buttonSpacerHeight = 0;
    }
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    // iOS7 屏幕长宽不会根据设备方向自动改变
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        //如果是横向 交换长宽
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            CGFloat tmp = screenWidth;
            screenWidth = screenHeight;
            screenHeight = tmp;
        }
    }
    
    return CGSizeMake(screenWidth, screenHeight);
}

// 添加 motion effects
- (void)addMotionEffects {
    UIInterpolatingMotionEffect *horizontalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalEffect.minimumRelativeValue = @(-kWMAlertMotionEffectExtent);
    horizontalEffect.maximumRelativeValue = @( kWMAlertMotionEffectExtent);
    
    UIInterpolatingMotionEffect *verticalEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalEffect.minimumRelativeValue = @(-kWMAlertMotionEffectExtent);
    verticalEffect.maximumRelativeValue = @( kWMAlertMotionEffectExtent);
    
    UIMotionEffectGroup *motionEffectGroup = [[UIMotionEffectGroup alloc] init];
    motionEffectGroup.motionEffects = @[horizontalEffect, verticalEffect];
    
    [self.dialogView addMotionEffect:motionEffectGroup];
}


#pragma mark - Device Orientation

// iOS处理方向变化
- (void)changeOrientationForIOS7 {
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGFloat startRotation = [[self valueForKeyPath:@"layer.transform.rotation.z"] floatValue];
    CGAffineTransform rotation;
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 270.0 / 180.0);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 90.0 / 180.0);
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            rotation = CGAffineTransformMakeRotation(-startRotation + M_PI * 180.0 / 180.0);
            break;
            
        default:
            rotation = CGAffineTransformMakeRotation(-startRotation + 0.0);
            break;
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.dialogView.transform = rotation;
                         
                     }
                     completion:nil
     ];
    
}

// iOS8以上处理方向
- (void)changeOrientationForIOS8:(NSNotification *)notification {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         CGSize dialogSize = [self dialogSize];
                         CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
                         self.frame = CGRectMake(0, 0, screenWidth, screenHeight);
                         self.dialogView.frame = CGRectMake((screenWidth - dialogSize.width) / 2, (screenHeight - keyboardSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
                     }
                     completion:nil
     ];
    
    
}

//监听设备方向改变
- (void)deviceOrientationDidChange:(NSNotification *)notification {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        [self changeOrientationForIOS7];
    } else {
        [self changeOrientationForIOS8:notification];
    }
}

#pragma mark - KeyBoard
//监听键盘弹起
- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize screenSize = [self screenSize];
    CGSize dialogSize = [self dialogSize];
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
        CGFloat tmp = keyboardSize.height;
        keyboardSize.height = keyboardSize.width;
        keyboardSize.width = tmp;
    }
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - keyboardSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
                     }
                     completion:nil
     ];
}
//监听键盘隐藏
- (void)keyboardWillHide:(NSNotification *)notification {
    CGSize screenSize = [self screenSize];
    CGSize dialogSize = [self dialogSize];
    
    [UIView animateWithDuration:0.2f delay:0.0 options:UIViewAnimationOptionTransitionNone
                     animations:^{
                         self.dialogView.frame = CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height);
                     }
                     completion:nil
     ];
}

#pragma mark - Touch

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_closeOnTouchUpOutside) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    if ([touch.view isKindOfClass:[WMAlertView class]]) {
        [self dismiss];
    }
}
@end
