//
//  CommandCenter.h
//  DronePan
//
//  Created by V Mahadev on 06/11/15.
//  Copyright © 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <DJISDK/DJISDK.h>
#import <DJISDK/DJIMainControllerDef.h>
#import "global.h"
#import "DroneDelegateHandler.h"
#import "Utils.h"

static DJIDrone *_drone;
static DJIInspireGimbal *_gimbal;
static DJIInspireCamera *_camera;
static DJIInspireMainController* mInspireMainController;
static DJIDroneType droneType;
static DroneDelegateHandler *droneDelegateHandler;


@interface DroneCommandCenter : NSObject{
    
}
+(void) initialize:(DJIDroneType)droneType;
+(void) changeDroneType:(DJIDroneType)droneType;

@end
