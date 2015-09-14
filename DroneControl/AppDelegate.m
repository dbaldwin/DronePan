//
//  AppDelegate.m
//  DroneControl
//
//  Created by Dennis Baldwin on 7/9/15.
//  Copyright (c) 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import <DJISDK/DJISDK.h>
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Keep ipad from sleeping
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    //Register App with key
    NSString* appKey = @"d6b78c9337f72fadd85d88e2";
    [DJIAppManager registerApp:appKey withDelegate:self];
    
    // Google Maps key
    //[GMSServices provideAPIKey:@"AIzaSyBoogFhIGflomT1WiR167fpybZIaax9-iU"];

    
    
    //self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    /*DJICamerViewController* vc = [[DJICamerViewController alloc] initWithNibName:@"DJICameraViewController" bundle:nil];
    self.window.rootViewController = vc;
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;*/
    
    
    // Override point for customization after application launch.
    return YES;
}

-(void) appManagerDidRegisterWithError:(int)error
{
    NSString* message = @"Failure";
    if (error == RegisterSuccess) {
        message = @"Success ";
        ViewController* vc = (ViewController*) self.window.rootViewController;
        [vc connectToDrone];
    }
    
    /*UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"App Registration" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];*/
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
