//
//  DJIInspireGimbal.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <DJISDK/DJIGimbal.h>

@interface DJIInspireGimbal : DJIGimbal
/**
 *  Start gimbal calibration
 *
 *  @param result Remote execute result.
 */
-(void) startGimbalAutoCalibrationWithResult:(DJIExecuteResultBlock)result;

/**
 *  Set gimbal's work mode
 *
 *  @param workMode Work mode
 *  @param result   Remote execute result.
 */
-(void) setGimbalWorkMode:(DJIGimbalWorkMode)workMode withResult:(DJIExecuteResultBlock)result;

/**
 *  Reset gimbal. the gimbal's pitch roll yaw will back to origin.
 *
 *  @param result Remote execute result.
 */
-(void) resetGimbalWithResult:(DJIExecuteResultBlock)result;

/**
 *  Gimbal's roll fine-tune. if fineTune is negative number, then the roll will adjust specificed angle anticlockwise. 1fineTune = 0.1degree
 *
 *  @param angle  Fine-tune angle
 *  @param result Remote execute result
 */
-(void) setGimbalRollFineTune:(int8_t)fineTune withResult:(DJIExecuteResultBlock)result;

/**
 *  Control gimbal rotate
 *
 *  @param pitch Pitch rotation parameters. angel is in range [-900, 300]. (real angle x10)
 *  @param roll  Roll rotation parameters. angel is in range [-1800, +1800]. (real angle x10)
 *  @param yaw   Yaw rotation parameters. angel is in range [-1800, +1800]. (real angle x10)
 *  @param block Remote execute result
 */
-(void) setGimbalPitch:(DJIGimbalRotation)pitch Roll:(DJIGimbalRotation)roll Yaw:(DJIGimbalRotation)yaw withResult:(DJIExecuteResultBlock)block;

@end
