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
static YawMode yawMode;


@interface DroneCommandCenter : NSObject{
    
}
+(void) initialize:(DJIDroneType)droneType;

+(void) changeDroneType:(DJIDroneType)droneType;

+(BOOL) hasGimbal;

+(void) connectToDrone;

+(void) resetGimbalYaw;

+(CommandResponseStatus) setDirection:(DroneDirection)direction;
+(CommandResponseStatus) setAbsoluteDirection:(DroneDirection)referenceDirection delta:(int)degrees;
+(CommandResponseStatus) calibrateDirectionToAbsolute:(DroneDirection)direction;
+(CommandResponseStatus) setCameraPitch:(float)pitch;
+(CommandResponseStatus) setCameraPosition:(float)pitch yaw:(float) yaw;
+(CommandResponseStatus) setCameraYaw:(float) yaw;

+(void) takeASnap;

+(void) sendNotification:(NSDictionary*)dictionary;
+(void) sendNotificationWithNoteType:(NoteType)noteType;
+(void) sendNotificationWithAdditionalInfo:(NoteType)noteType additionalInfo:(NSDictionary*) dictionary;

@end
