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
    
    devices=[[CommandCenterDevices alloc]init];
    devices.droneDelegateHandler=[[DroneDelegateHandler alloc] init];
    
    /*DJIDrone *drone = [[DJIDrone alloc] initWithType: DJIDrone_Inspire];
    
    drone.delegate = droneDelegateHandler;
    
    [drone connectToDrone];
    */
    
    switch(droneType){
        
        case DJIDrone_Inspire:
        {
            devices.drone = [[DJIDrone alloc] initWithType: DJIDrone_Inspire];
            break;
        }
            
        case DJIDrone_Phantom:
        {
            devices.drone=[[DJIDrone alloc] initWithType: DJIDrone_Phantom];
            break;
        }
        default:{ break;}//Throw Exception
    }
    
    if(devices.drone==nil){
        
        [DroneCommandCenter sendNotificationWithNoteType:CmdCenterDroneTypeUnknown];
        
        return;
    }
    
    devices.drone.delegate = devices.droneDelegateHandler;
    
    devices.gimbal = (DJIInspireGimbal*)devices.drone.gimbal;
    devices.gimbal.delegate = devices.droneDelegateHandler;
    
    devices.camera = (DJIInspireCamera*)devices.drone.camera;
    devices.camera.delegate = devices.droneDelegateHandler;
    
    devices.mMainController = (DJIInspireMainController*)devices.drone.mainController;
    devices.mMainController.mcDelegate = devices.droneDelegateHandler;
    
    [DroneCommandCenter connectToDrone];
}

+(void) changeDroneType:(DJIDroneType)droneType {
    
    droneType=droneType;
    
    NSDictionary* droneInfo = @{@"NoteType":@(CmdCenterDroneChanged),@"drone": [NSNumber numberWithInt: droneType]};
    
    [DroneCommandCenter sendNotification:droneInfo];
    
}

+(BOOL) hasGimbal{
    
    _Bool hasG=false;
    
    switch(devices.droneType)
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
    [devices.drone connectToDrone];
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

+(void)resetGimbalYaw{
    
    [devices.gimbal resetGimbalWithResult: nil];
}
+(CommandResponseStatus) setCameraPitch:(float)pitch {
    DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
    
    DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
    
    pitchRotation.angle = pitch;
    
    pitchRotation.angleType = AbsoluteAngle;
    
    pitchRotation.direction = pitchDir;
    
    pitchRotation.enable = YES;
    
    [devices.gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
        
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
    
    if(devices.yawMode==Gimbal)
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
        
        [devices.gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
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
    
    if(devices.yawMode==Aircraft)
    {
        DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
        
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        
        pitchRotation.angle = pitch;
        
        pitchRotation.angleType = AbsoluteAngle;
        
        pitchRotation.direction = pitchDir;
        
        pitchRotation.enable = YES;
        
        yawRotation.enable=NO;
        
        [devices.gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
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
        
        [devices.drone.mainController.navigationManager.flightControl sendFlightControlData:ctrlData withResult:^(DJIError *error) {
            NSLog(@"Callback -----------------------+++++++++++++++++------------------------ worked!");
        }];
        
      
        
    }
    
    
    return success;
}


+(CommandResponseStatus) setCameraYaw:(float) yaw{

    if(devices.yawMode==Gimbal)
    {
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        pitchRotation.enable = NO;
        

        yawRotation.angle = yaw;
        
        yawRotation.angleType = AbsoluteAngle;
        
        yawRotation.direction = RotationForward;
        
        yawRotation.enable = YES;
        
        [devices.gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
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
    
    if(devices.yawMode==Aircraft)
    {//90 Relative Works so just keep sending 90
        
        DJIFlightControlData ctrlData;
        ctrlData.mPitch = 0;
        ctrlData.mRoll = 0;
        ctrlData.mThrottle = 0;
        ctrlData.mYaw = yaw;
        
        [devices.drone.mainController.navigationManager.flightControl sendFlightControlData:ctrlData withResult:^(DJIError *error) {
            NSLog(@"Callback -----------------------+++++++++++++++++------------------------ worked!");
        }];
        
        NSLog(@"Aircraft Command Sent");
    }
    
    
    return success;
}

+(void) takeASnap{
    
    [devices.camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
        
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
