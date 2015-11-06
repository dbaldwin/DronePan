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
}
-(void) gimbalController:(DJIGimbal *)controller didGimbalError:(DJIGimbalError)error{
    NSLog(@"Gimbal Error");
}
-(void) gimbalController:(DJIGimbal *)controller didUpdateGimbalState:(DJIGimbalState *)gimbalState{
    NSLog(@"Update Gimbal State");
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
