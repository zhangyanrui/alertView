//
//  ViewController.m
//  WMAlertView
//
//  Created by Will on 2017/4/26.
//  Copyright © 2017年 iwm. All rights reserved.
//

#import "ViewController.h"
#import "WMAlertView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showAlert:(UIButton *)sender {
    
//    UIView *aView = [[[UINib nibWithNibName:@"ContentView" bundle:nil] instantiateWithOwner:self options:nil] firstObject];
    
    WMAlertView *alert = [[WMAlertView alloc] initWithTitleString:@"Whenever possible, use Interface Builder to set your constraints. Interface Builder provides a wide range of tools to visualize, edit, manage, and debug your constraints. By analyzing your constraints, it also reveals many common errors at design time, letting you find and fix problems before your app even runs." containerView:nil buttonTitles:@[@"YES",@"NO"] buttonStyles:@[@(0), @(0),@(3)] delegate:nil];
    
    [alert regsiterContainerViewWithNibName:@"ContentView"];
    [alert show];
}

@end
