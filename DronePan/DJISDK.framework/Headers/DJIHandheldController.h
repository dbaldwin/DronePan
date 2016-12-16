//
//  DJIHandheldController.h
//  DJISDK
//
//  Copyright © 2015, DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJIBaseComponent.h>
#import <DJISDK/DJIHandheldControllerBaseTypes.h>

@class DJIWiFiLink;

NS_ASSUME_NONNULL_BEGIN

@class DJIHandheldController;

/*********************************************************************************/
#pragma mark - DJIHandheldControllerDelegate
/*********************************************************************************/

/**
 *
 *  This protocol provides a delegate method to receive the updated power mode of the handheld controller.
 *
 */
@protocol DJIHandheldControllerDelegate <NSObject>

@optional

/**
 *  Tells the delegate that a handheld controller's power mode has been updated.
 *
 *  @param controller   The handheld controller that updates the power mode.
 *  @param powerMode    The handheld controller's current power mode.
 *
 */
- (void)handheldController:(DJIHandheldController *_Nonnull)controller didUpdatePowerMode:(DJIHandheldPowerMode)powerMode;

/**
 *  Delegate for the handheld controller's current hardware state (e.g. the
 *  state of the physical buttons and joysticks).
 *  Supported only by Osmo Mobile. 
 *
 *  @param controller   The handheld controller that updates the hardware state.
 *  @param powerMode    The handheld controller's current hardware state.
 *
 */
- (void)handheldController:(DJIHandheldController *_Nonnull)controller didUpdateHardwareState:(DJIHandheldControllerHardwareState *)state;

@end


/*********************************************************************************/
#pragma mark - DJIHandheldController
/*********************************************************************************/

/**
 *
 *  This class contains interfaces to control a handheld device. You can make the handheld device enter sleep mode, awake from sleep mode or shut it down.
 */
@interface DJIHandheldController : DJIBaseComponent

/**
 *  Returns the `DJIHandheldController` delegate.
 */
@property(nonatomic, weak) id <DJIHandheldControllerDelegate> delegate;

/**
 *  Set the power mode for the handheld.
 *
 *  @param mode     The power mode to set.
 *                  CAUTION: When the mode is `DJIHandheldPowerModePowerOff`, the handheld device will be shut down and
 *                  the connection will be broken. The user must then power on the device manually.
 *  @param block    Remote execution result callback block.
 */
- (void)setHandheldPowerMode:(DJIHandheldPowerMode)mode withCompletion:(DJICompletionBlock)block;

/**
 *  Controls the LED of the handheld controller.
 *
 *  @param command  The command to control the LED.
 *  @param block    Remote execution result callback block.
 */
- (void)controlLEDWithCommand:(DJIHandheldControllerLEDCommand *)command
               withCompletion:(DJICompletionBlock)block;

/**
 *  Enables/disables joystick control of the gimbal.
 *  By default, it is enabled. The handheld will be reset to the default value 
 *  when it reboots or SDK reinitializes. When gimbal control is disabled, the
 *  joystick can be used for other purposes in an SDK application by reading its
 *  position values with `joystickVerticalDirection` and `joystickHorizontalDirection`.
 *  It is only supported in firmware version 1.2.0.40 or above.
 *
 *  @param enabled  `YES` to enable the gimbal control.
 *  @param block    Remote execution result callback block.
 */
- (void)setStickGimbalControlEnabled:(BOOL)enabled withCompletion:(DJICompletionBlock)block;

/**
 *  Gets if the gimbal control with the joystick is enabled or not.
 *  It is only supported in firmware version 1.2.0.40 or above.
 *
 *  @param block    Remote execution result callback block.
 */
- (void)getStickGimbalControlEnabledWithCompletion:(void(^)(BOOL enabled, NSError *_Nullable error))block;

@end

NS_ASSUME_NONNULL_END
