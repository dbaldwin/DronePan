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
    
   // [DroneCommandCenter sendNotificationWithNoteType:CmdCenterDroneNotConnected];

}

+(void) initialize:(DJIDroneType)droneType{
   
   
    
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

    if(_drone==nil){
        
        [DroneCommandCenter sendNotificationWithNoteType:CmdCenterDroneTypeUnknown];
        
        return;
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
    
    NSDictionary* droneInfo = @{@"NoteType":@(CmdCenterDroneChanged),@"drone": [NSNumber numberWithInt: droneType]};
    
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

+(void) connectToDrone {
    [_drone connectToDrone];
}

+(void)resetGimbalYaw{
    
    [_gimbal resetGimbalWithResult: nil];
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

+(CommandResponseStatus) setCameraPitch:(float)pitch {
    DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
    
    DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
    
    pitchRotation.angle = pitch;
    
    pitchRotation.angleType = AbsoluteAngle;
    
    pitchRotation.direction = pitchDir;
    
    pitchRotation.enable = YES;
    
    [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
        
        if(error.errorCode != ERR_Succeeded) {
            
            NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
            
            NSLog(@"%@",myerror);
            
            [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed];
            
            
        }else{
            
            [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationSuccess];
            
            [Utils displayToast:[UIApplication sharedApplication].keyWindow.rootViewController.view message:@"Gimbal Rotation Success"];
            
        }
    }];
    
    return success;
}
+(CommandResponseStatus) setCameraPosition:(float)pitch yaw:(float) yaw{
    
    if(yawMode==Gimbal)
    {
        DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
        
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        
        pitchRotation.angle = pitch;
        
        pitchRotation.angleType = AbsoluteAngle;
        
        pitchRotation.direction = pitchDir;
        
        pitchRotation.enable = YES;
        
        
        yawRotation.angle = yaw;
        
        yawRotation.angleType = AbsoluteAngle;
        
        yawRotation.direction = RotationForward;
        
        yawRotation.enable = YES;
        
        [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
            if(error.errorCode != ERR_Succeeded) {
                
                NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
                
                NSLog(@"%@",myerror);
                
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed];
                
                
            }else{
                
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationSuccess];
                
                [Utils displayToast:[UIApplication sharedApplication].keyWindow.rootViewController.view message:@"Gimbal Rotation Success"];
                
            }
        }];
    }
    
    if(yawMode==Aircraft)
    {
        DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
        
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        
        pitchRotation.angle = pitch;
        
        pitchRotation.angleType = AbsoluteAngle;
        
        pitchRotation.direction = pitchDir;
        
        pitchRotation.enable = YES;
        
        yawRotation.enable=NO;
        
        [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
            if(error.errorCode != ERR_Succeeded) {
                
                NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
                
                NSLog(@"%@",myerror);
                
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed];
                
                
            }else{
                
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationSuccess];
                
                [Utils displayToast:[UIApplication sharedApplication].keyWindow.rootViewController.view message:@"Gimbal Rotation Success"];
                
            }
        }];

        
        DJIFlightControlData ctrlData;
        ctrlData.mPitch = 0;
        ctrlData.mRoll = 0;
        ctrlData.mThrottle = 0;
        ctrlData.mYaw = yaw;
        
        [_drone.mainController.navigationManager.flightControl sendFlightControlData:ctrlData withResult:^(DJIError *error) {
            NSLog(@"Callback -----------------------+++++++++++++++++------------------------ worked!");
        }];
        
      
        
    }
    
    
    return success;
}


+(CommandResponseStatus) setCameraYaw:(float) yaw{

    if(yawMode==Gimbal)
    {
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        pitchRotation.enable = NO;
        

        yawRotation.angle = yaw;
        
        yawRotation.angleType = AbsoluteAngle;
        
        yawRotation.direction = RotationForward;
        
        yawRotation.enable = YES;
        
        [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
            if(error.errorCode != ERR_Succeeded) {
                    
                    NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
                    
                    NSLog(@"%@",myerror);
                
                    [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed];
                    
                   
            }else{
                    
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationSuccess];
                
                [Utils displayToast:[UIApplication sharedApplication].keyWindow.rootViewController.view message:@"Gimbal Rotation Success"];
             
            }
        }];
    }
    
    if(yawMode==Aircraft)
    {//90 Relative Works so just keep sending 90
        
        DJIFlightControlData ctrlData;
        
        ctrlData.mPitch = 0;
        ctrlData.mRoll = 0;
        ctrlData.mThrottle = 0;
        ctrlData.mYaw = yaw;
        
        [_drone.mainController.navigationManager.flightControl sendFlightControlData:ctrlData withResult:^(DJIError *error) {
            NSLog(@"Callback -----------------------+++++++++++++++++------------------------ worked!");
        }];
        
        NSLog(@"Aircraft Command Sent");
    }
    
    
    return success;
}

+(void) takeASnap{
    
    [_camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
        
        if (error.errorCode != ERR_Succeeded) {
            
            NSString* myerror = [NSString stringWithFormat: @"Take photo error code: %lu", (unsigned long)error.errorCode];
            [Utils displayToastOnApp:myerror];
        
        }else{
            [Utils displayToastOnApp:@"Click!"];
        }
    }];

}

+(void) sendNotification:(NSDictionary*)dictionary{
    
    [Utils sendNotification:NotificationCmdCenter dictionary:dictionary];
}

+(void) sendNotificationWithNoteType:(NoteType)noteType{
    
    [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:noteType];
}

+(void) sendNotificationWithAdditionalInfo:(NoteType)noteType additionalInfo:(NSDictionary*) dictionary{
    
    [Utils sendNotificationWithAdditionalInfo:NotificationCmdCenter noteType:noteType additionalInfo:dictionary];

}
@end
