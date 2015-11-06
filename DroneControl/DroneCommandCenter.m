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
    
    NSDictionary* droneNCInfo = @{@"NoteType":@(CmdCenter_DroneNotConnected)};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DroneCommandCenter"
                                                        object:nil
                                                      userInfo:droneNCInfo];

}

+(void) initialize:(DJIDroneType)droneType{
    
}

+(void) changeDroneType:(DJIDroneType)droneType {
    
    droneType=droneType;
    
    NSDictionary* droneInfo = @{@"NoteType":@(CmdCenter_DroneChanged),@"drone": [NSNumber numberWithInt: droneType]};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DroneCommandCenter"
                                                        object:nil
                                                      userInfo:droneInfo];
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

+(CommandResponseStatus) calibrateToAbsolute:(DroneDirection)direction{
    
    
    return success;
}


@end
