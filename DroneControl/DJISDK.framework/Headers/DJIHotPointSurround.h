//
//  DJIHotPointSurround.h
//  DJIVisionSDK
//
//  Created by Ares on 15/4/13.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <DJISDK/DJIFoundation.h>
#import <DJISDK/DJIObject.h>
#import <DJISDK/DJINavigation.h>

/**
 *  Max surrounding radius
 */
DJI_API_EXTERN const float DJIMaxSurroundingRadius;

/**
 *  Entry point position relative to the hot point
 */
typedef NS_ENUM(NSUInteger, DJIHotPointSurroundEntryPoint){
    /**
     *  Entry from the north
     */
    SurroundEntryFromNorth,
    /**
     *  Entry from the south
     */
    SurroundEntryFromSouth,
    /**
     *  Entry from the west
     */
    SurroundEntryFromWest,
    /**
     *  Entry from the east
     */
    SurroundEntryFromEast,
    /**
     *  Entry from point which nesrest to the current position
     */
    SurroundEntryFromNearest,
};

/**
 *  Speed level for the aircraft while surrounding the hot point
 */
typedef NS_ENUM(NSUInteger, DJIHotPointSurroundSpeedLevel){
    /**
     *  Default speed
     */
    SurroundSpeedDefault,
    /**
     *  Low speed, Not support now
     */
    SurroundSpeedLow,
    /**
     *  Fast speed, Not support now
     */
    SurroundSpeedFast,
};

/**
 *  Heading mode for aircraft while surrounding the hot point
 */
typedef NS_ENUM(NSUInteger, DJIHotPointSurroundHeadingMode){
    /**
     *  Along the circle
     */
    SurroundHeadingAlongTheCircle,
    /**
     *  Toward the hot point
     */
    SurroundHeadingTowardHotPoint,
    /**
     *  Backward the hot point
     */
    SurroundHeadingBackwardHotPoint,
    /**
     *  Control by remote controller
     */
    SurroundHeadingControlByRemoteController,
    /**
     *  Using initial direction always
     */
    SurroundHeadingUsingInitialDirection
};

/**
 *  The hotpoint mission executing state
 */
typedef NS_ENUM(uint8_t, DJIHotpointMissionExecutePhase){
    /**
     *  Initializing
     */
    HotpointMissionInitialing,
    /**
     *  Executing
     */
    HotpointMissionExecuting,
};

@interface DJIHotpointMissionStatus : DJINavigationMissionStatus

/**
 *  Execute phase
 */
@property(nonatomic, readonly) DJIHotpointMissionExecutePhase currentPhase;

/**
 *  The current radius to the hotpoint
 */
@property(nonatomic, readonly) float currentRadius;

/**
 *  The angle, reference to the north
 */
@property(nonatomic, readonly) float currentAngle;

@end


/**
 *  Mission for Hot point surround action
 */
@interface DJIHotPointSurroundMission : NSObject

/**
 *  Hot point coordinate in degree
 */
@property(nonatomic, assign) CLLocationCoordinate2D hotPoint;

/**
 *  Hot point altitude in meter. relate to the ground.
 */
@property(nonatomic, assign) float altitude;

/**
 *  Radius in meter for surrounding. should not be larger than DJIMaxSurroundingRadius
 */
@property(nonatomic, assign) float surroundRadius;

/**
 *  Surround the hot point in clockwise
 */
@property(nonatomic, assign) BOOL clockwise;

/**
 *  Speed level
 */
@property(nonatomic, assign) DJIHotPointSurroundSpeedLevel speedLevel;

/**
 *  Entry point of the aircraft when start to surround
 */
@property(nonatomic, assign) DJIHotPointSurroundEntryPoint entryPoint;

/**
 *  Heading of aircraft while in surrounding
 */
@property(nonatomic, assign) DJIHotPointSurroundHeadingMode headingMode;

/**
 *  Init mission instance using coordinate
 *
 *  @param coordinate Hot point coordinate
 *
 *  @return Mission Instance
 */
-(id) initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end

@protocol DJIHotPointSurround <DJINavigation>

@required

/**
 *  Current execute mission
 */
@property(nonatomic, readonly) DJIHotPointSurroundMission* currentHotPointMisson;

/**
 *  Set mission
 *
 *  @param mission Mission to be execute
 */
-(void) setHotPointSurroundMission:(DJIHotPointSurroundMission*)mission;

/**
 *  Start execute hot point surround mission. Will enter NavigationMissionHotpoint mode.
 *
 *  @param result Remote execute result
 */
-(void) startHotPointMissionWithResult:(DJIExecuteResultBlock)result;

/**
 *  Pasue execute hot point surround mission
 *
 *  @param result Remote execute result
 */
-(void) pauseHotPointMissionWithResult:(DJIExecuteResultBlock)result;

/**
 *  Resume hot point surround mission
 *
 *  @param result Remote execute result
 */
-(void) resumeHotPointMissionWithResult:(DJIExecuteResultBlock)result;

/**
 *  Stop hot point surround mission
 *
 *  @param result Remote execute result
 */
-(void) stopHotPointMissionWithResult:(DJIExecuteResultBlock)result;

@end
