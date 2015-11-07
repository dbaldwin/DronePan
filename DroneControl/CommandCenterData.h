//
//  CommandCenterData.h
//  DronePan
//
//  Created by V Mahadev on 08/11/15.
//  Copyright © 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJISDK.h>
#import <DJISDK/DJIMainControllerDef.h>
#import "global.h"
#import "DroneDelegateHandler.h"


@interface CommandCenterData : NSObject{

   /* DJIDrone *_drone;
    DJIInspireGimbal *_gimbal;
    DJIInspireCamera *_camera;
    DJIInspireMainController* mInspireMainController;
    DJIDroneType droneType;
    DroneDelegateHandler *droneDelegateHandler;
    YawMode yawMode;*/
}

@property (strong, nonatomic)DJIDrone *drone;
@property (strong, nonatomic)DJIInspireGimbal *gimbal;
@property (strong, nonatomic)DJIInspireCamera *camera;
@property (strong, nonatomic)DJIInspireMainController *mMainController;
@property (assign, nonatomic)DJIDroneType droneType;
@property (strong, nonatomic)DroneDelegateHandler *droneDelegateHandler;
@property (assign, nonatomic)YawMode yawMode;
@end
