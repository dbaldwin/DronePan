//
//  DJIGroundStationTask.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DJIGroundStationWaypoint;

/**
 *  Action of task when finished
 */
typedef NS_ENUM(NSUInteger, DJIGSTaskFinishedAction){
    /**
     *  No action. aircraft exit the waypoint mission and hover in the air. could controled by the remote controller.
     */
    GSTaskFinishedNoAction,
    /**
     *  Aircraft will go home
     */
    GSTaskFinishedGoHome,
    /**
     *  Aircraft will auto landing
     */
    GSTaskFinishedAutoLanding,
    /**
     *  Aircraft will go to the first waypoint
     */
    GSTaskFinishedGoFirstWaypoint
};

/**
 *  Heading mode
 */
typedef NS_ENUM(NSUInteger, DJIGSHeadingMode){
    /**
     *  Aircraft's heading toward to the next waypoint
     */
    GSHeadingTowardNextWaypoint,
    /**
     *  Aircraft's heading using the initial direction
     */
    GSHeadingUsingInitialDirection,
    /**
     *  Aircraft's heading control by the remote controller
     */
    GSHeadingControlByRemoteController,
    /**
     *  Aircraft's heading using the waypoint's heading value
     */
    GSHeadingUsingWaypointHeading,
};

@interface DJIGroundStationTask : NSObject
{
    NSMutableArray* _waypointsArray;
}

/**
 *  Waypoints count in the task.
 */
@property(nonatomic, readonly) int waypointCount;

/**
 *  The first waypoint index of task.
 */
@property(nonatomic, assign) int startWaypointIndex;

/**
 *  Whether execute task looply. Default is NO
 */
@property(nonatomic, assign) BOOL isLoop;

/**
 *  Max vertical velocity [0, 5] m/s
 */
@property(nonatomic, assign) float maxVerticalVelocity;

/**
 *  Max horizontal velocity [0, 7] m/s
 */
@property(nonatomic, assign) float maxHorizontalVelocity;

/**
 *  Max angular velocity in the mission. [30, 180] degree/s. default is 100 degree/s
 */
@property(nonatomic, assign) float maxAngularVelocity;

/**
 *  Max execute time for the task. if execute time over, then the aircraft will exit the waypoint mission and enter go home mode. [60, 1500] second.
 */
@property(nonatomic, assign) uint16_t maxExecuteTime;

/**
 *  Action for the aircraft while the task finished
 */
@property(nonatomic, assign) DJIGSTaskFinishedAction finishedAction;

/**
 *  How the aircraft heading while executing task
 */
@property(nonatomic, assign) DJIGSHeadingMode headingMode;

/**
 *  Create new task
 *
 */
+(id) newTask;

/**
 *  Add waypoint, The maximum waypoint count is 100 for Inspire/Matrice100/Phantom3Pro/Phantom3Adv. 16 for Phantom2Vision/Phantom2Vision+
 *
 *  @param waypoint
 */
-(void) addWaypoint:(DJIGroundStationWaypoint*)waypoint;

/**
 *  Remove one waypoint
 *
 *  @param waypoint Waypoint will be removed
 */
-(void) removeWaypoint:(DJIGroundStationWaypoint*)waypoint;

/**
 *  Remove all waypoints
 */
-(void) removeAllWaypoint;

/**
 *  Get waypoint at index
 *
 *  @param index Index of array
 *
 *  @return Waypoint object
 */
-(DJIGroundStationWaypoint*) waypointAtIndex:(int)index;

/**
 *  Get all waypoints
 *
 *  @return Waypoint array
 */
-(NSArray*) allWaypoints;

@end
