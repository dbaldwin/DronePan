//
//  DJIVisionDetectionState.h
//  DJISDK
//
//  Copyright © 2016, DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DJISDKFoundation.h"

/**
 *  Position of the sensor on the aircraft.
 */
typedef NS_ENUM(NSUInteger, DJIVisionSensorPosition) {
    /**
     *  The sensor is on the front or nose of the aircraft.
     */
    DJIVisionSensorPositionNose,
    /**
     *  The sensor is on the back or tail of the aircraft.
     */
    DJIVisionSensorPositionTail,
    /**
     *  The sensor is on the right or starboard side of the aircraft.
     */
    DJIVisionSensorPositionRight,
    /**
     *  The sensor is on the left or port side of the aircraft.
     */
    DJIVisionSensorPositionLeft,
};

/**
 *  Distance warning returned by each sector of the front vision system. 
 *  Warning Level 4 is the most serious level.
 */
typedef NS_ENUM (NSInteger, DJIVisionSectorWarning){
    /**
     *  The warning level is invalid. The sector cannot determine depth of the
     *  scene in front of it.
     */
    DJIVisionSectorWarningInvalid,
    /**
     *  The distance between the obstacle detected by the sector and the 
     *  aircraft is over 4 meters.
     */
    DJIVisionSectorWarningLevel1,
    /**
     *  The distance between the obstacle detected by the sector and the
     *  aircraft is between 3 - 4 meters.
     */
    DJIVisionSectorWarningLevel2,
    /**
     *  The distance between the obstacle detected by the sector and the
     *  aircraft is between 2 - 3 meters.
     */
    DJIVisionSectorWarningLevel3,
    /**
     *  The distance between the obstacle detected by the sector and the
     *  aircraft is less than 2 meters.
     */
    DJIVisionSectorWarningLevel4,
    /**
     *  The distance warning is unknown. This warning is returned when an
     *  exception occurs.
     */
    DJIVisionSectorWarningUnknown = 0xFF
};

/**
 *  Distance warning returned by the front vision system. Warning Level 4 is the
 *  most serious level.
 */
typedef NS_ENUM (NSInteger, DJIVisionSystemWarning){
    /**
     *  The warning is invalid. The front vision system cannot determine depth
     *  of the scene in front of it.
     */
    DJIVisionSystemWarningInvalid,
    /**
     *  The distance between the obstacle detected by the vision system and the
     *  aircraft is safe (over 2 meters).
     */
    DJIVisionSystemWarningSafe,
    /**
     *  The distance between the obstacle detected by the vision system and the
     *  aircraft is dangerous (less than 2 meters).
     */
    DJIVisionSystemWarningDangerous,
    /**
     *  The distance warning is unknown. This warning is returned when an
     *  exception occurs.
     */
    DJIVisionSystemWarningUnknown = 0xFF
};

/**
 *  The vision system can see in front of the aircraft with a 60 degree
 *  horizontal field of view (FOV) and 55-degree vertical FOV. The horizontal
 *  FOV is split into four equal sectors, and this class gives the distance and
 *  warning level for one sector.
 */
@interface DJIVisionDetectionSector : NSObject

/**
 *  The detected obstacle distance to the aircraft in meters.
 */
@property(nonatomic, readonly) double obstacleDistanceInMeters;

/**
 *  The warning level based on distance.
 */
@property(nonatomic, readonly) DJIVisionSectorWarning warningLevel;

@end

/**
 *  This class gives state information about the product's vision sensors used
 *  for obstacle detection. The two types of sensors used are dual camera
 *  sensors operating in the visible spectrum (dual-camera sensor) and infrared
 *  time of flight (TOF) sensors. Note, Inspire 2's upward facing infrared TOF
 *  sensor is not returned in this state. It is accessed through `DJIVisionControlState`.
 *
 */
@interface DJIVisionDetectionState : NSObject

/**
 *  `YES` if the aircraft is braking automatically to avoid collision.
 *
 *  @deprecated Use `isBraking` in `DJIVisionControlState` instead.
 */
@property(nonatomic, readonly) BOOL isBraking DJI_API_DEPRECATED("Use isBraking in DJIVisionControlState instead. ");

/**
 *  The vision sensor's position on the aircraft.
 *  For Phantom 4 Pro, there are 4 vision sensors on the aircraft.
 *  The sensors on the nose and tail are dual-camera sensors. The sensors on
 *  the left and right are infrared time-of-flight (TOF) sensors.
 */
@property(nonatomic, readonly) DJIVisionSensorPosition position;

/**
 *  `YES` if the vision sensor is working.
 */
@property(nonatomic, readonly) BOOL isSensorWorking;

/**
 *  Obstacle detection warning level for the vision sensor. 
 *  Note: dual-camera vision sensors have a field of view (FOV) split into 
 *  sectors. This warning level is a combination of all sectors.
 */
@property(nonatomic, readonly) DJIVisionSystemWarning systemWarning;

/**
 *  The distance to the closest detected obstacle in meters.
 *  It is only used when the sensor is an infrared TOF sensor. The valid range
 *  is [0.3, 5.0].
 *  Phantom 4 Pro has two infrared sensors on the left and right of the product.
 *  Both sensors have a 70-degree horizontal field of view (FOV) and 20-degree 
 *  vertical FOV. The value is always 0.0 if the sensor is a dual-camera sensor
 *  or the sensor is not working properly.
 */
@property(nonatomic, readonly) double obstacleDistanceInMeters;

/**
 *  A dual-camera vision sensor can see an area with a 60-degree horizontal
 *  field of view (FOV) and 55-degree vertical FOV. The horizontal FOV is split
 *  into four equal sectors and this array contains the distance and warning
 *  information for each sector.
 *  Phantom 4, Mavic Pro and Inspire 2 have one dual-camera vision sensor in the
 *  nose of the aircraft.
 *  For Phantrom 4 Pro, the dual-camera vision sensors are on the nose and the
 *  tail. 
 *  It is nil if it is an infrared sensor or the sensor is not working properly.
 */
@property(nullable, nonatomic, readonly) NSArray<DJIVisionDetectionSector *> *detectionSectors;

@end

/**
 *  Landing protection status returned by the downward vision sensor.
 */
typedef NS_ENUM (NSInteger, DJIVisionLandingProtectionStatus){
    /**
     *  The aircraft is not executing auto-landing or the downward vision sensor
     *  has not started to analyze the ground yet.
     */
    DJIVisionLandingProtectionStatusNone,
    /**
     *  The downward vision sensor is analyzing the ground at the landing zone.
     */
    DJIVisionLandingProtectionStatusAnalyzing,
    /**
     *  The downward vision sensor's analysis failed. Either the auto-landing
     *  can be attempted again, or the user needs to land the aircraft manually.
     */
    DJIVisionLandingProtectionStatusAnalysisFailed,
    /**
     *  The ground is considered safe to land on automatically.
     */
    DJIVisionLandingProtectionStatusSafeToLand,
    /**
     *  Landing area is not considered safe enough for an automatic landing.
     *  This will usually happen if over uneven terrain, or water.
     *  The aircraft should be moved to an area that is more flat and an
     *  auto-land should be attempted again or the user should land the
     *  aircraft manually.
     */
    DJIVisionLandingProtectionStatusNotSafeToLand,
    /**
     *  Unknown.
     */
    DJIVisionLandingProtectionStatusUnknown = 0xFF
};

/**
 *  This class gives the aircraft's state controlled by the intelligent flight
 *  assistant.
 */
@interface DJIVisionControlState : NSObject

/**
 *  `YES` if the aircraft is braking automatically to avoid collision.
 */
@property (nonatomic, readonly) BOOL isBraking;

/**
 *  `YES` if the aircraft will not ascend further because of an obstacle
 *  detected within 1m above it.
 */
@property (nonatomic, readonly) BOOL isAscentLimitedByObstacle;

/**
 *  `YES` if the aircraft is avoiding collision from an obstacle moving towards
 *  the aircraft.
 */
@property (nonatomic, readonly) BOOL isAvoidingActiveObstacleCollision;

/**
 *  `YES` if the aircraft is landing precisely.
 */
@property (nonatomic, readonly) BOOL isPerformingPrecisionLanding;

/**
 *  Status of the landing protection.
 */
@property (nonatomic, readonly) DJIVisionLandingProtectionStatus landingProtectionStatus;

@end
