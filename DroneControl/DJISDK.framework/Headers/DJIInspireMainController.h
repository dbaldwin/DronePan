//
//  DJIInspireMainController.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <DJISDK/DJIMainController.h>
#import <DJISDK/DJIHotPointSurround.h>
#import <DJISDK/DJIGroundStation.h>


@interface DJIInspireMainController : DJIMainController <DJIHotPointSurround, DJIGroundStation>
/**
 *  Open tripod protection. If opened, the tripod will drop down automatically while the drone landing
 *
 *  @param block Remote execute reult
 */
-(void) openTripodProtectionWithResult:(DJIExecuteResultBlock)block;

/**
 *  Close tripod protection
 *
 *  @param block Remote execute reult
 */
-(void) closeTripodProtectionWithResult:(DJIExecuteResultBlock)block;

/**
 *  Lock the course using current direction
 *
 *  @param block Remote execute result.
 */
-(void) lockCourseUsingCurrentDirectionWithResult:(DJIExecuteResultBlock)block;

/**
 *  Set dynamic home point enable
 *
 *  @param enable Dynamic home point enable
 *  @param block  Remote execute result.
 */
-(void) setDynamicHomePointEnable:(BOOL)enable withResult:(DJIExecuteResultBlock)block;

/**
 *  Enter transport mode. if receive ERR_CommandExecuteFailed error, that maybe the gimbal is not dismount or the ground is not flattening.
 *
 *  @param block Remote execute result.
 */
-(void) enterTransportModeWithResult:(DJIExecuteResultBlock)block;

/**
 *  Exit transport mode.
 *
 *  @param block Remote execute result.
 */
-(void) exitTransportModeWithResult:(DJIExecuteResultBlock)block;

/**
 *  Set IOC Mode enable
 *
 *  @param enable Ioc mode enable
 *  @param block  Remote execute result.
 */
-(void) setIOCModeEnable:(BOOL)enable withResult:(DJIExecuteResultBlock)block;

/**
 *  Set IOC type.
 *
 *  @param type   IOC Type
 *  @param result Remote execute result.
 */
-(void) setAircraftIOCType:(DJIMCIocType)type withResult:(DJIExecuteResultBlock)result;

/**
 *  Get IOC type
 *
 *  @param result Remote execute result.
 */
-(void) getAircraftIOCTypeWithResult:(void(^)(DJIMCIocType type, DJIError* error))result;

/*
 *  Set low battery waning data, percentage of voltage in range [25, 50]. action will be performed by the aircraft while battery is reach the specific percent.
 */
-(void) setLowBatteryWarning:(uint8_t)percent action:(DJIMCLowBatteryAction)action withResult:(DJIExecuteResultBlock)block;

/**
 *  Get low battery warning data.
 *
 *  @param result Remote execute result.
 */
-(void) getLowBatteryWarningWithResult:(void(^)(uint8_t percent, DJIMCLowBatteryAction action, DJIError* error))result;

/**
 *  Set serious low battery waning data, percentage of voltage in range [10, 25]. action will be performed by the aircraft while battery is reach the specific percent.
 *
 *  @param percent Percentage of serious low battery
 *  @param action  What action will be done when the aircraft is at serious low battery
 *  @param block   Remote execute result.
 */
-(void) setSeriousLowBattery:(uint8_t)percent action:(DJIMCLowBatteryAction)action withResult:(DJIExecuteResultBlock)block;

/**
 *  Get serious low battery warning data.
 *
 *  @param result Remote execute result.
 */
-(void) getSeriousLowBatteryWarningwithResult:(void(^)(uint8_t percent, DJIMCLowBatteryAction action, DJIError* error))result;

/**
 *  Set home point use the aircraft's current location.
 *
 *  @param result Remote execute result.
 */
-(void) setHomePointUsingAircraftCurrentLocationWithResult:(DJIExecuteResultBlock)result;

/**
 *  Set home point use the remote controller's current location.
 *
 *  @param result Remote exeucte result.
 */
-(void) setHomePointUsingRCCurrentLocationWithResult:(DJIExecuteResultBlock)result;

/**
 *  Set aircraft name. the length of aircraft name should be less than 32 characters
 *
 *  @param name   Name to be set to the aricraft.
 *  @param result Remote execute result.
 */
-(void) setAircraftName:(NSString*)name withResult:(DJIExecuteResultBlock)result;

/**
 *  Get aircraft name.
 *
 *  @param result Remote execute result.
 */
-(void) getAircraftNameWithResult:(void(^)(NSString* name, DJIError* error))result;

@end
