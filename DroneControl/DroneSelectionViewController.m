//
//  DroneSelectionViewController.m
//  DronePan
//
//  Created by Dennis Baldwin on 9/7/15.
//  Copyright (c) 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import "DroneSelectionViewController.h"

@interface DroneSelectionViewController ()

@end

@implementation DroneSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)p3Selected:(id)sender {
    NSDictionary* userInfo = @{@"drone": @"p3"};
    // Let the parent know p3 was selected
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DroneSelected"
                                                        object:nil
                                                      userInfo:userInfo];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}

- (IBAction)i1Selected:(id)sender {
    NSDictionary* userInfo = @{@"drone": @"i1"};
    // Let the parent know i1 was selected
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DroneSelected"
                                                        object:nil
                                                      userInfo:userInfo];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Hide the status bar
-(BOOL)prefersStatusBarHidden{
    return YES;
}
@end
