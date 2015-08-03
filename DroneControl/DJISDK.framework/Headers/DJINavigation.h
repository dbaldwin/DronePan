//
//  DJINavigation.h
//  DJISDK
//
//  Created by Ares on 15/4/14.
//  Copyright (c) 2015年 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJIObject.h>
#import <DJISDK/DJIFoundation.h>

typedef NS_ENUM(uint8_t, DJINavigationMissionType)
{
    /**
     *  No mission
     */
    NavigationMissionNone,
    /**
     *  Waypoint mission
     */
    NavigationMissionWaypoint,
    /**
     *  Hotpoint mission
     */
    NavigationMissionHotpoint,
    /**
     *  Followme mission, Not support now
     */
    NavigationMissionFollowme,
    /**
     *  Unknown mission
     */
    NavigationMissionUnknown
};

/**
 *  Navigation mission status
 */
@interface DJINavigationMissionStatus : NSObject

@property(nonatomic, readonly) DJINavigationMissionType missionType;

-(id) initWithType:(DJINavigationMissionType)type;

@end

/**
 *  Navigation event type
 */
typedef NS_ENUM(uint8_t, DJINavigationEventType){
    /**
     *  Mission upload finished event
     */
    NavigationEventMissionUploadFinished,
    /**
     *  Mission execute finished event
     */
    NavigationEventMissionExecuteFinished,
    /**
     *  Aircraft reach target waypoint event
     */
    NavigationEventWaypointReached,
};

/**
 *  Navigation event
 */
@interface DJINavigationEvent : NSObject

/**
 *  Event type
 */
@property(nonatomic, readonly) DJINavigationEventType eventType;

/**
 *  Init event object by type
 *
 *  @param type Event type
 *
 *  @return Event instance
 */
-(id) initWithEventType:(DJINavigationEventType)type;

@end

/**
 *  Sub event for mission upload finished
 */
@interface DJINavigationMissionUploadFinishedEvent : DJINavigationEvent

/**
 *  Is the uploaded mission valid.
 */
@property(nonatomic, readonly) BOOL isMissionValid;

-(id) initWithEventData:(NSData*)data;

@end

/**
 *  The action of aircraft while finished execute mission
 */
typedef NS_ENUM(uint8_t, DJINavigationMissionExecuteFinishedAction){
    /**
     *  No action, hover at current position
     */
    NavigationMissionFinishedActionNone,
    /**
     *  Will restart the mission again
     */
    NavigationMissionFinishedRestart,
    /**
     *  Will go home
     */
    NavigationMissionFinishedGoHome,
    /**
     *  Will auto landing
     */
    NavigationMissionFinishedAutoLanding,
};

/**
 *  Subclass of navigation event
 */
@interface DJINavigationMissionExecuteFinishedEvent : DJINavigationEvent

/**
 *  Mission finished action
 */
@property(nonatomic, readonly) DJINavigationMissionExecuteFinishedAction missionFinishedAction;

-(id) initWithEventData:(NSData*)data;

@end

/**
 *  Subclass of navigation event
 */
@interface DJINavigationWaypointReachedEvent : DJINavigationEvent

/**
 *  Waypoint index current reached
 */
@property(nonatomic, readonly) NSInteger waypointIndex;

-(id) initWithEventData:(NSData*)data;

@end

/**
 *  Flight control's coordinate system
 */
typedef NS_ENUM(uint8_t, DJINavigationFlightControlCoordinateSystem){
    /**
     *  Ground coordinate system
     */
    NavigationFlightControlCoordinateSystemGround,
    /**
     *  Body coordinate system
     */
    NavigationFlightControlCoordinateSystemBody,
};

/**
 *  Min vertical flight control velocity
 */
DJI_API_EXTERN const float DJIVerticalFlightControlVelocityMin;
/**
 *  Max vertical flight control velocity
 */
DJI_API_EXTERN const float DJIVerticalFlightControlVelocityMax;
/**
 *  Min vertical flight control position
 */
DJI_API_EXTERN const float DJIVerticalFlightControlPositionMin;
/**
 *  Min vertical flight control throttle
 */
DJI_API_EXTERN const float DJIVerticalFlightControlThrottleMin;
/**
 *  Max vertical flight control throttle
 */
DJI_API_EXTERN const float DJIVerticalFlightControlThrottleMax;

/**
 *  Flight control's vertical control mode, will affect the mThrottle of DJINavigationFlightControlData
 */
typedef NS_ENUM(uint8_t, DJINavigationFlightControlVerticalControlMode){
    /**
     *  The vertical control value is velocity value. mThrottle value will in range [-4, 4] m/s
     */
    NavigationFlightControlVerticalControlVelocity,
    /**
     *  The vertical control value is position value. mThrottle value will in range [0, +∞) m. value is offset value to the current position.
     */
    NavigationFlightControlVerticalControlPosition,
    /**
     *  The vertical control value is percentage of throttle. mThrottle value will in range [0, 100]
     */
    NavigationFlightControlVerticalControlThrottle,
};

/**
 *  Max horizontal flight control velocity
 */
DJI_API_EXTERN const float DJIHorizontalFlightControlVelocityMax;
/**
 *  Min horizontal flight control velocity
 */
DJI_API_EXTERN const float DJIHorizontalFlightControlVelocityMin;
/**
 *  Max horizontal flight control angle
 */
DJI_API_EXTERN const float DJIHorizontalFlightControlAngleMax;
/**
 *  Min horizontal flight control angle
 */
DJI_API_EXTERN const float DJIHorizontalFlightControlAngleMin;

/**
 *  Flight control horizontal control mode, will affect the mPitch and mRoll of DJINavigationFlightControlData
 */
typedef NS_ENUM(uint8_t, DJINavigationFlightControlHorizontalControlMode){
    /**
     *  The horizontal control value is angle value. mPitch and mRoll will in range [-30, 30] degree
     */
    NavigationFlightControlHorizontalControlAngle,
    /**
     *  The horizontal control value is velocity value. mPitch and mRoll will in range [-10, +10] m/s
     */
    NavigationFlightControlHorizontalControlVelocity,
    /**
     *  The horizontal control value is position value. mPitch and mRoll is in range (-∞, +∞) m. value is offset value to the current position.
     */
    NavigationFlightControlHorizontalControlPosition,
};

/**
 *  Max yaw flight control angle
 */
DJI_API_EXTERN const float DJIYawFlightControlAngleMax;
/**
 *  Min yaw flight control angle
 */
DJI_API_EXTERN const float DJIYawFlightControlAngleMin;
/**
 *  Max yaw flight control palstance
 */
DJI_API_EXTERN const float DJIYawFlightControlPalstanceMax;
/**
 *  Min yaw flight control palstance
 */
DJI_API_EXTERN const float DJIYawFlightControlPalstanceMin;

/**
 *  Flight control yaw control mode, will affect the mYaw of DJINavigationFlightControlData
 */
typedef NS_ENUM(uint8_t, DJINavigationFlightControlYawControlMode){
    /**
     *  The Yaw control value is angle value, mYaw will in range [-180, 180] degree
     */
    NavigationFlightControlYawControlAngle,
    /**
     *  The Yaw control value is palstance value. mYaw will in range [-100, 100] degree/s
     */
    NavigationFlightControlYawControlPalstance,
};

/**
 *  Flight controlled quantity
 */
typedef float DJINavigationFlightControlledQuantity;

typedef struct
{
    /**
     *  Aircraft's Pitch controlled quantity.
     */
    DJINavigationFlightControlledQuantity mPitch;
    /**
     *  Aircraft's Roll controlled quantity.
     */
    DJINavigationFlightControlledQuantity mRoll;
    /**
     *  Aircraft's Yaw controlled quantity.
     */
    DJINavigationFlightControlledQuantity mYaw;
    /**
     *  Aircraft's Throttle controlled quantity.
     */
    DJINavigationFlightControlledQuantity mThrottle;
} DJINavigationFlightControlData;


@protocol DJINavigationDelegate <NSObject>

@required

/**
 *  Mission status update
 *
 *  @param missionStatus Mission status for different mission
 */
-(void) onNavigationMissionStatusChanged:(DJINavigationMissionStatus*)missionStatus;

/**
 *  Mission event post
 *
 *  @param event Event post from different mission
 */
-(void) onNavigationPostMissionEvents:(DJINavigationEvent*)event;

@end

@protocol DJINavigation <NSObject>

@property(nonatomic, weak) id<DJINavigationDelegate> navigationDelegate;
/**
 *  Vertical control mode
 */
@property(nonatomic, assign) DJINavigationFlightControlVerticalControlMode verticalControlMode;
/**
 *  Horizontal control mode
 */
@property(nonatomic, assign) DJINavigationFlightControlHorizontalControlMode horizontalControlMode;
/**
 *  Yaw control mode
 */
@property(nonatomic, assign) DJINavigationFlightControlYawControlMode yawControlMode;
/**
 *  Horizontal control coordinate system
 */
@property(nonatomic, assign) DJINavigationFlightControlCoordinateSystem horizontalControlCoordinateSystem;
/**
 *  Yaw control coordinate system
 */
@property(nonatomic, assign) DJINavigationFlightControlCoordinateSystem yawControlCoordinateSystem;

/**
 *  Enter navigation mode. To success enter the navigation mode, the remote controller's mode switch should be switched to 'A' mode. if the switch has alerdy at 'A' mode, then user must switch back and forth to enable navigation control.
 *
 *  @param result Remote execute result
 */
-(void) enterNavigationModeWithResult:(DJIExecuteResultBlock)result;

/**
 *  Get current navigation mission type
 *
 *  @param result Remote execute result.
 */
-(void) getCurrentNavigationMissionTypeWithResult:(void(^)(DJINavigationMissionType type, DJIError* error))result;

/**
 *  Exit navigation mode
 *
 *  @param result Remote execute result
 */
-(void) exitNavigationModeWithResult:(DJIExecuteResultBlock)result;

/**
 *  Control the aricraft. To use this api successfully, the aircraft shouldn't have other mission in executing.
 *
 *  @param controlData Control data sent to the aircraft
 *  @param result      Remote execute result.
 */
-(void) sendFlightControlData:(DJINavigationFlightControlData)controlData withResult:(DJIExecuteResultBlock)result;

@end
