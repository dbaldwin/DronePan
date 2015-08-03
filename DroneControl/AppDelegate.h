//
//  AppDelegate.h
//  DroneControl
//
//  Created by Dennis Baldwin on 7/9/15.
//  Copyright (c) 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DJISDK/DJISDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, DJIAppManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@end

