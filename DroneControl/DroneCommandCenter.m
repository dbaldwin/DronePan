//
//  CommandCenter.m
//  DronePan
//
//  Created by V Mahadev on 06/11/15.
//  Copyright © 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import "DroneCommandCenter.h"


@implementation DroneCommandCenter

+(void) initialize{
    //Command Center needs to detect
    
    [DroneCommandCenter sendNotificationWithNoteType:CmdCenter_DroneNotConnected];

}

+(void) initialize:(DJIDroneType)droneType{
   
    if(_drone==nil){
        
        [DroneCommandCenter sendNotificationWithNoteType:CmdCenter_DroneTypeUnknown];
        
        return;
    }
    
    switch(droneType){
        
        case DJIDrone_Inspire:
        {
            _drone = [[DJIDrone alloc] initWithType: DJIDrone_Inspire];
            break;
        }
            
        case DJIDrone_Phantom:
        {
            _drone=[[DJIDrone alloc] initWithType: DJIDrone_Phantom];
            break;
        }
        default:{break;}
    }

    
    _drone.delegate = droneDelegateHandler;
    
    _gimbal = (DJIInspireGimbal*)_drone.gimbal;
    _gimbal.delegate = droneDelegateHandler;
    
    _camera = (DJIInspireCamera*)_drone.camera;
    _camera.delegate = droneDelegateHandler;
    
    mInspireMainController = (DJIInspireMainController*)_drone.mainController;
    mInspireMainController.mcDelegate = droneDelegateHandler;
   
}

+(void) changeDroneType:(DJIDroneType)droneType {
    
    droneType=droneType;
    
    NSDictionary* droneInfo = @{@"NoteType":@(CmdCenter_DroneChanged),@"drone": [NSNumber numberWithInt: droneType]};
    
    [DroneCommandCenter sendNotification:droneInfo];
    
}

+(BOOL) hasGimbal{
    
    _Bool hasG=false;
    
    switch(droneType)
    {
        case DJIDrone_Inspire:
            hasG=true;
            break;
        case DJIDrone_Phantom3Advanced:
        case DJIDrone_Phantom3Professional:
        case DJIDrone_Phantom:
        case DJIDrone_Unknown:
        default:
            hasG=false;
    }
    
    return hasG;
}

+(CommandResponseStatus) setDirection:(DroneDirection)direction{
    
    
    return success;
}


+(CommandResponseStatus) setAbsoluteDirection:(DroneDirection)referenceDirection delta:(int)degrees{
    
    
    return success;
}

+(CommandResponseStatus) calibrateDirectionToAbsolute:(DroneDirection)direction{
    
    
    return success;
}

+(CommandResponseStatus) setCameraPosition:(int)pitch yaw:(int) yaw{

    
    return success;
}


+(void) sendNotification:(NSDictionary*)dictionary{
    
    [Utils sendNotification:@"DroneCommandCenter" dictionary:dictionary];
}

+(void) sendNotificationWithNoteType:(NoteType)noteType{
    
    [Utils sendNotificationWithNoteType:@"DroneCommandCenter" noteType:noteType];
    
}

+(void) sendNotificationWithAdditionalInfo:(NoteType)noteType additionalInfo:(NSDictionary*) dictionary{
    
    [Utils sendNotificationWithAdditionalInfo:@"DroneCommandCenter" noteType:noteType additionalInfo:dictionary];

}
@end
