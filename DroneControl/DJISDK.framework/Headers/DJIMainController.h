//
//  DJIMainController.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJIObject.h>
#import <DJISDK/DJIGroundStation.h>
#import <DJISDK/DJIMainControllerDef.h>
#import <DJISDK/DJIFoundation.h>

@class DJIMCSystemState;
@class DJIMCTripodState;
@class DJIMainController;

@protocol DJIMainControllerDelegate <NSObject>

@optional

/**
 *  Notify on main controller error
 *
 */
-(void) mainController:(DJIMainController*)mc didMainControlError:(MCError)error;

/**
 *  Update main controller system state
 *
 */
-(void) mainController:(DJIMainController*)mc didUpdateSystemState:(DJIMCSystemState*)state;

/**
 *  Update tripod state
 *
 */
-(void) mainController:(DJIMainController*)mc didUpdateTripodState:(DJIMCTripodState*)state;

@end


@interface DJIMainController : DJIObject

/**
 *  Manin controller delegate
 */
@property(nonatomic, weak) id<DJIMainControllerDelegate> mcDelegate;

/**
 *  Main controller's firmware version.
 *
 */
-(NSString*) getMainControllerVersion;

/**
 *  Start update main controller's system state
 */
-(void) startUpdateMCSystemState;

/**
 *  Stop update main controller's system state
 */
-(void) stopUpdateMCSystemState;

/**
 *  Start Takeoff
 *
 *  @param block Remote execute result.
 */
-(void) startTakeoffWithResult:(DJIExecuteResultBlock)block;

/**
 *  Stop takeoff
 *
 *  @param block Remote execute result.
 */
-(void) stopTakeoffWithResult:(DJIExecuteResultBlock)block;

/**
 *  Start auto landing
 *
 *  @param block Remote execute result.
 */
-(void) startLandingWithResult:(DJIExecuteResultBlock)block;

/**
 *  Stop auto landing
 *
 *  @param block Remote execute result.
 */
-(void) stopLandingWithResult:(DJIExecuteResultBlock)block;

/**
 *  Turn on the motor
 *
 *  @param block Remote execute result.
 */
-(void) turnOnMotorWithResult:(DJIExecuteResultBlock)block;

/**
 *  Turn off the motor
 *
 *  @param block Remote execute result.
 */
-(void) turnOffMotorWithResult:(DJIExecuteResultBlock)block;

/**
 *  Start go home
 *
 *  @param block Remote execute result
 */
-(void) startGoHomeWithResult:(DJIExecuteResultBlock)block;

/**
 *  Stop go home mode
 *
 *  @param block Remote execute result.
 */
-(void) stopGoHomeWithResult:(DJIExecuteResultBlock)block;

/**
 *  Start compass calibration
 *
 *  @param block Remote execute result.
 */
-(void) startCompassCalibrationWithResult:(DJIExecuteResultBlock)block;

/**
 *  Stop compass calibration
 *
 *  @param block Remote execute result.
 */
-(void) stopCompassCalibrationWithResult:(DJIExecuteResultBlock)block;

/**
 *  Set the fly limitation parameter.
 *
 *  @param limitParam The max height and distance parameters
 *  @param block      Remote execute result
 */
-(void) setLimitFlyWithHeight:(float)height Distance:(float)distance withResult:(DJIExecuteResultBlock)block;

/**
 *  Get the limit fly parameter. if execute success, result will be set to 'limitFlyParameter'
 *
 *  @param block Remote execute result
 */
-(void) getLimitFlyWithResultBlock:(void(^)(DJILimitFlyStatus limitStatus, DJIError*))block;

/**
 *  Set a no fly zone. Not support now.
 *
 *  @param noFlyZone No fly zone parameter
 *  @param block     Remote execute result
 */
-(void) setNoFly:(DJINoFlyZone)noFlyZone withResult:(DJIExecuteResultBlock)block DJI_API_DEPRECATED;

/**
 *  Set home point to drone. Home point is use for back home when the drone lost signal or other case.
 *  The drone use current located location as default home point while it first start and receive enough satellite( >= 6).
 *  User should be carefully to change the home point.
 *
 *  @param homePoint Home point in degree.
 *  @param block     Remote execute result
 */
-(void) setHomePoint:(CLLocationCoordinate2D)homePoint withResult:(DJIExecuteResultBlock)block;

/**
 *  Get home point of drone.
 *
 *  @param block   Remote execute result. The homePoint is in degree.
 */
-(void) getHomePoint:(void(^)(CLLocationCoordinate2D homePoint, DJIError* error))block;

/**
 *  Set go home default altitude. The default altitude is used by the drone every time while going home.
 *
 *  @param altitude  Drone altitude in meter for going home.
 *  @param block     Remote execute result
 */
-(void) setGoHomeDefaultAltitude:(float)altitude withResult:(DJIExecuteResultBlock)block;

/**
 *  Get the default altitude of go home.
 *
 *  @param block  Remote execute result
 */
-(void) getGoHomeDefaultAltitude:(void(^)(float altitude, DJIError* error))block;

/**
 *  Set go home temporary altitude. The temporary altitude is used by the drone this time while going home.
 *
 *  @param block     Remote execute result
 */
-(void) setGoHomeTemporaryAltitude:(float)tmpAltitude withResult:(DJIExecuteResultBlock)block;

/**
 *  Get go home default altitude.
 *
 *  @param block  Remote execute result
 */
-(void) getGoHomeTemporaryAltitude:(void(^)(float altitude, DJIError* error))block;

@end
