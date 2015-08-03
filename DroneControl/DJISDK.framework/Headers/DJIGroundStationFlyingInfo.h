//
//  DJIGroundStationFlightInfo.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <DJISDK/DJIMainController.h>

typedef NS_ENUM(NSUInteger, GroundStationControlMode)
{
    GSModeManual,
    GSModeGpsCruise,
    GSModeGpsAtti,
    GSModeAtti,
    GSModeWaypoint,
    GSModeGohome,
    GSModePause,
    GSModeLanding,
    GSModeTakeOff,
    GSModeUnknown,
};

typedef NS_ENUM(NSUInteger, GroundStationGpsStatus)
{
    GSGpsGood,
    GSGpsWeak,
    GSGpsBad,
    GSGpsUnknown,
};

typedef NS_ENUM(NSUInteger, GroundStationDroneStatus)
{
    GSDroneDeadStick,
    GSDroneTakingOff,
    GSDroneInFlying,
    GSDroneUnknown,
};

@interface DJIGroundStationFlyingInfo : NSObject

/**
 *  Target waypoint index that will fly to. -1 if the task not start
 */
@property(nonatomic, readonly) int targetWaypointIndex;

/**
 *  Satellite count. if the satelliteCount >= 6, home point will be set
 */
@property(nonatomic, readonly) int satelliteCount;

/**
 *  Home point
 */
@property(nonatomic, readonly) CLLocationCoordinate2D homeLocation;

/**
 *  Current location of the drone
 */
@property(nonatomic, readonly) CLLocationCoordinate2D droneLocation;

/**
 *  The target waypoint location will fly to
 */
@property(nonatomic, readonly) CLLocationCoordinate2D targetWaypointLocation;

/**
 *  Speed on x (m/s)
 */
@property(nonatomic, readonly) float velocityX;

/**
 *  Speed on y (m/s)
 */
@property(nonatomic, readonly) float velocityY;

/**
 *  Speed on z (m/s)
 */
@property(nonatomic, readonly) float velocityZ;

/**
 *  Altitude of the drone, (0.1m)
 */
@property(nonatomic, readonly) float altitude;

/**
 *  The target altitude will flying to (0.1m)
 */
@property(nonatomic, readonly) float targetAltitude;

/**
 *  Attitude of the drone
 */
@property(nonatomic, readonly) DJIAttitude attitude;

/**
 *  Control mode
 */
@property(nonatomic, readonly) GroundStationControlMode controlMode;

/**
 *  Gps status : good, weak, bad
 */
@property(nonatomic, readonly) GroundStationGpsStatus gpsStatus;

/**
 *  Drone status:
 */
@property(nonatomic, readonly) GroundStationDroneStatus droneStatus;

@end
