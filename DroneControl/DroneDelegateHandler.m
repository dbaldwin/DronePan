//
//  DroneDelegateHandler.m
//  DronePan
//
//  Created by V Mahadev on 06/11/15.
//  Copyright © 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import "DroneDelegateHandler.h"

@implementation DroneDelegateHandler

- (id) init
{
    self = [super init];

    return self;
}

-(void) droneOnConnectionStatusChanged:(DJIConnectionStatus)status{
    
    NSLog(@"Drone Connection Status Changed");
    
    //[Utils displayToastOnApp:@"Connection Status Changed"];
    
    switch(status){
            
        case ConnectionSucceeded:{
            
            NSLog(@"Connection Succeeded");
            
            [Utils sendNotificationWithNoteType:NotificationDroneConnected noteType:CmdCenterDroneConnected];
        
            break;
        }
        
        case ConnectionBroken:{
            
            NSLog(@"Connection Broken");
            
            [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterDroneNotConnected];
            
            break;
        }
        
        case ConnectionFailed:{
            
            NSLog(@"Connection Failed");
            
            [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterDroneConnectionFailed];
            
            break;
        }
        
        case ConnectionStartConnect:
       
        default:break;
            
    }
}

-(void) gimbalController:(DJIGimbal *)controller didGimbalError:(DJIGimbalError)error{
  
    NSLog(@"Gimbal Error");

}

-(void) gimbalController:(DJIGimbal *)controller didUpdateGimbalState:(DJIGimbalState *)

    gimbalState{
    
    NSLog(@"Update Gimbal State");
    
    NSLog(@"Is Calibrating %@",@(gimbalState.isCalibrating));
    
    NSLog(@"Is Pitch Reach Max %@",@(gimbalState.isPitchReachMax));
    
    NSLog(@"Is Roll Reach Max %@",@(gimbalState.isRollReachMax));
    
    NSLog(@"Is Yaw Reach Max %@",@(gimbalState.isYawReachMax));
    
    
    [Utils sendNotification:NotificationPitchAndYaw dictionary:@{@"Yaw":[NSString stringWithFormat:@"Yaw : %10.3f", gimbalState.attitude.yaw],@"Pitch":[NSString stringWithFormat:@"Pitch : %10.3f", gimbalState.attitude.pitch]}];
 
}

-(void) mainController:(DJIMainController *)mc didMainControlError:(MCError)error{
    NSLog(@"Main Controller Error:");
}

-(void)mainController:(DJIMainController *)mc didReceivedDataFromExternalDevice:(NSData *)data{
    NSLog(@"Main Controller : Received Data From External Device");
}
-(void)mainController:(DJIMainController *)mc didUpdateLandingGearState:(DJIMCLandingGearState *)state{
    NSLog(@"Main Controller : Update Landing Gear State");
}
-(void)mainController:(DJIMainController *)mc didUpdateSystemState:(DJIMCSystemState *)state{
    NSLog(@"Main Controller : Update System State");
    DJIMCSystemState* inspireSystemState = (DJIMCSystemState*)state;
    {
        //self.droneAltitude = inspireSystemState.altitude;
        [Utils sendNotification:NotificationAltitude dictionary:@{@"Alt":[NSString stringWithFormat: @"Alt: %10.3f", inspireSystemState.altitude]}];
    }
}

-(void)onNavigationMissionStatusChanged:(DJINavigationMissionStatus *)missionStatus{
    NSLog(@"On Mission Status Changed");
}

-(void)camera:(DJICamera *)camera didGeneratedNewMedia:(DJIMedia *)newMedia{
    NSLog(@"Generated New Media");
}
-(void)camera:(DJICamera *)camera didReceivedVideoData:(uint8_t *)videoBuffer length:(int)length{
    NSLog(@"Received Video Data");
}
-(void)camera:(DJICamera *)camera didUpdatePlaybackState:(DJICameraPlaybackState *)playbackState{
    NSLog(@"Update Playback State");
}
-(void)camera:(DJICamera *)camera didUpdateSystemState:(DJICameraSystemState *)systemState{
    NSLog(@"Update System State");
}
@end
