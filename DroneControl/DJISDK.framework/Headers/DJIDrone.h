//
//  DJIDrone.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DJICamera;
@class DJIMainController;
@class DJIGimbal;
@class DJIRangeExtender;
@class DJIBattery;
@class DJIImageTransmitter;
@class DJIRemoteController;
@class DJIMediaManager;
@class DJIError;
@protocol DJIDroneDelegate;

/**
 *  Drone type
 */
typedef NS_ENUM(NSInteger, DJIDroneType){
    /**
     *  Type for product Phantom 2 vision / Phantom 2 vision+
     */
    DJIDrone_Phantom,
    /**
     *  Type for product Inspire / Matrice 100
     */
    DJIDrone_Inspire,
    /**
     *  Type for product Phantom3 Professional
     */
    DJIDrone_Phantom3Professional,
    /**
     *  Type for product Phantom3 Advanced
     */
    DJIDrone_Phantom3Advanced,
    /**
     *  Unknown type
     */
    DJIDrone_Unknown,
};

typedef NS_ENUM(NSUInteger, DJIConnectionStatus)
{
    /**
     *  Start reconnect: Broken -> Reconnect -> Successed/Failed
     */
    ConnectionStartConnect,
    /**
     *  Reconnect successed: Reconnect -> Successed -> Broken
     */
    ConnectionSuccessed,
    /**
     *  Reconnect Failed: Reconnect -> Failed -> Reconnect
     */
    ConnectionFailed,
    /**
     *  Connection broken: Successed -> Broken -> Reconnect
     */
    ConnectionBroken,
};

@interface DJIDrone : NSObject
{
    DJIDroneType _droneType;
}

/**
 *  Drone delegate
 */
@property(nonatomic, weak) id<DJIDroneDelegate> delegate;

/**
 *  Drone type
 */
@property(nonatomic, readonly) DJIDroneType droneType;

/**
 *  Drone's camera.
 */
@property(nonatomic, readonly) DJICamera* camera;

/**
 *  Drone's main controller.
 */
@property(nonatomic, readonly) DJIMainController* mainController;

/**
 *  Drone's gimbal.
 */
@property(nonatomic, readonly) DJIGimbal* gimbal;

/**
 *  Range extender.
 */
@property(nonatomic, readonly) DJIRangeExtender* rangeExtender;

/**
 *  Smart battery
 */
@property(nonatomic, readonly) DJIBattery* smartBattery;

/**
 *  Image transmitter
 */
@property(nonatomic, readonly) DJIImageTransmitter* imageTransmitter;

/**
 *  Remote Controller
 */
@property(nonatomic, readonly) DJIRemoteController* remoteController;

/**
 *  init drone object with type
 *
 */
-(id) initWithType:(DJIDroneType)type;

/**
 *  Connect to the drone. once this function was called, the DJIDrone will automatically connect to the drone
 */
-(void) connectToDrone;

/**
 *  Disconnect to the drone.
 */
-(void) disconnectToDrone;

/**
 *  Destroy the drone object, user should call this interface to release all objects.
 */
-(void) destroy;

@end

@protocol DJIDroneDelegate <NSObject>

/**
 *  Notify on connection status changed.
 *
 *  @param status Connection status
 */
-(void) droneOnConnectionStatusChanged:(DJIConnectionStatus)status;

@end