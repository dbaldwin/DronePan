//
//  DJIMCSystemState.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <DJISDK/DJIMainController.h>
#import <DJISDK/DJIMCSmartGoHome.h>

/**
 *  Flight mode of main controller
 */
typedef NS_ENUM(NSUInteger, DJIMainControllerFlightMode){
    /**
     *  Manual mode. Used in phantom 2 Vision
     */
    ManualMode,
    /**
     *  Gps mode. Used in phantom 2 Vision
     */
    GPSMode,
    /**
     *  Out of control mode. Used in phantom 2 Vision
     */
    OutOfControlMode,
    /**
     *  Attitude mode. Used in phantom 2 Vision
     */
    AttitudeMode,
    /**
     *  Go home mode. Used in phantom 2 Vision
     */
    GoHomeMode,
    /**
     *  Landing mode. Used in phantom 2 Vision
     */
    LandingMode,
    
    
    /**
     *  Manual mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeManual = 0,
    /**
     *  Attitude mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeAtti = 1,
    /**
     *  Attitude course lock mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeAttiCourseLock = 2,
    /**
     *  Attitude hover mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeAttiHover = 3,
    /**
     *  Hover mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeHover = 4,
    /**
     *  Gps blake mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeGPSBlake = 5,
    /**
     *  Gps Attitude mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeGPSAtti = 6,
    /**
     *  Gps course lock mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeGPSCourseLock = 7,
    /**
     *  Gps Home mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeGPSHomeLock = 8,
    /**
     *  Gps hot point mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeGPSHotPoint = 9,
    /**
     *  Assisted takeoff mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeAssistedTakeOff = 10,
    /**
     *  Auto takeoff mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeAutoTakeOff = 11,
    /**
     *  Auto landing mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeAutoLanding = 12,
    /**
     *  Attitude landing mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeAttiLanding = 13,
    /**
     *  GPS Waypoint mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeGPSWaypoint = 14,
    /**
     *  Go home mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeGoHome = 15,
    /**
     *  Click go mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeClickGo = 16,
    /**
     *  Joystick mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeJoystick = 17,
    /**
     *  Attitude limited mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeAttiLimited = 23,
    /**
     *  Gps attitude limited mode. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeGPSAttiLimited = 24,
    /**
     *  Gps Follow me. Used in Inspire / Phantom3 Professional / M100
     */
    InspireFlightModeGPSFollowMe = 25,
    /**
     *  Unknown
     */
    UnknownMode = 0xFF,
};

/**
 *  No fly status
 */
typedef NS_ENUM(NSUInteger, DJIMainControllerNoFlyStatus){
    /**
     *  Drone normal flying
     */
    DroneNormalFlying,
    /**
     *  Drone is in a no fly zone, take off prohibited
     */
    DroneTakeOffProhibited,
    /**
     *  Drone is in a no fly zone, will force landing
     */
    DroneFroceAutoLanding,
    /**
     *  Drone is approaching to a no fly zone
     */
    DroneApproachingNoFlyZone,
    /**
     *  Drone had reach the max flying height
     */
    DroneReachMaxFlyingHeight,
    /**
     *  Drone had reach the max flying distance
     */
    DroneReachMaxFlyingDistance,
    /**
     *  Drone is in a no fly zone, the flying heigh will limited
     */
    DroneUnderLimitFlyZone,
    /**
     *  Unknown status
     */
    UnknownStatus,
};

@interface DJIMCSystemState : NSObject

/**
 *  Satellite count.
 */
@property(nonatomic, readonly) int satelliteCount;

/**
 *  Home location of the drone
 */
@property(nonatomic, readonly) CLLocationCoordinate2D homeLocation;

/**
 *  Current location of the drone
 */
@property(nonatomic, readonly) CLLocationCoordinate2D droneLocation;

/**
 *  Speed x (m/s)
 */
@property(nonatomic, readonly) float velocityX;

/**
 *  Speed y (m/s)
 */
@property(nonatomic, readonly) float velocityY;

/**
 *  Speed z (m/s)
 */
@property(nonatomic, readonly) float velocityZ;

/**
 *  Altitude of the drone, (0.1m)
 */
@property(nonatomic, readonly) float altitude;

/**
 *  Attitude of the drone, Pitch[-180, 180], Roll[-180, 180], Yaw[-180, 180]
 */
@property(nonatomic, readonly) DJIAttitude attitude;

/**
 *  Power level of the drone: 0 - very low power warning, 1- low power warning, 2 - height power, 3 - full power
 */
@property(nonatomic, readonly) int powerLevel;

/**
 *  Whether the drone is in flying
 */
@property(nonatomic, readonly) BOOL isFlying;

/**
 *  Flight mode
 */
@property(nonatomic, readonly) DJIMainControllerFlightMode flightMode;

/**
 *  No fly status
 */
@property(nonatomic, readonly) DJIMainControllerNoFlyStatus noFlyStatus;

/**
 *  The no fly zone center coordinate
 */
@property(nonatomic, readonly) CLLocationCoordinate2D noFlyZoneCenter;

/**
 *  The no fly zone radius
 */
@property(nonatomic, readonly) int noFlyZoneRadius;

/**
 *  Smart go home data
 */
@property(nonatomic, readonly) DJIMCSmartGoHomeData* smartGoHomeData;

@end


@interface DJIInspireMCSystemState : DJIMCSystemState
/**
 *  If the remote controller signal lost, then failsafe.
 */
@property(nonatomic, readonly) BOOL isFailsafe;
/**
 *  Is IMU in pre-heating
 */
@property(nonatomic, readonly) BOOL isIMUPreheating;
/**
 *  Is compass error
 */
@property(nonatomic, readonly) BOOL isCompassError;
/**
 *  Is ultrasonic working
 */
@property(nonatomic, readonly) BOOL isUltrasonicWorking;
/**
 *  Is vision working
 */
@property(nonatomic, readonly) BOOL isVisionWorking;
/**
 *  Is motor working
 */
@property(nonatomic, readonly) BOOL isMotorWorking;
/**
 *  Is IOC working
 */
@property(nonatomic, readonly) BOOL isIOCWorking;
/**
 *  Flight mode string. ex. "P-GPS", "P-Atti"
 */
@property(nonatomic, readonly) NSString* flightModeString;

@end
