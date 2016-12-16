//
//  DJIIntelligentFlightAssistant.h
//  DJISDK
//
//  Copyright © 2016, DJI. All rights reserved.
//

#import <DJISDK/DJIBaseProduct.h>

NS_ASSUME_NONNULL_BEGIN

@class DJIIntelligentFlightAssistant;
@class DJIVisionDetectionState;
@class DJIVisionControlState; 

/**
 *
 *  This protocol provides a delegate method to update the Intelligent Flight
 *  Assistant current state.
 *
 */
@protocol DJIIntelligentFlightAssistantDelegate <NSObject>

@optional

/**
 *  Callback function that updates the detection state of each vision sensor.
 *
 *  @param assistant    Intelligent flight assistant that has the updated state.
 *  @param state        The state of vision sensor.
 */
- (void)intelligentFlightAssistant:(DJIIntelligentFlightAssistant *_Nonnull)assistant
     didUpdateVisionDetectionState:(DJIVisionDetectionState *_Nonnull)state;

/**
 *  Callback function that updates the aircraft state controlled by the
 *  intelligent flight assistant.
 *
 *  @param assistant    Intelligent flight assistant that has the updated state.
 *  @param state        The control state.
 */
- (void)intelligentFlightAssistant:(DJIIntelligentFlightAssistant *_Nonnull)assistant
       didUpdateVisionControlState:(DJIVisionControlState *_Nonnull)state;

@end

/**
 *  This class contains components of the Intelligent Flight Assistant and
 *  provides methods to change the settings of Intelligent Flight Assistant.
 */
@interface DJIIntelligentFlightAssistant : NSObject

/**
 *  Intelligent flight assistant delegate.
 */
@property(nonatomic, weak) id<DJIIntelligentFlightAssistantDelegate> delegate;

/**
 *  Set collision avoidance enabled. When collision avoidance is enabled, the
 *  aircraft will stop and try to go around an obstacle when detected.
 */
- (void)setCollisionAvoidanceEnabled:(BOOL)enable
                      withCompletion:(DJICompletionBlock)completion;

/**
 *  Get collision avoidance enabled.
 */
- (void)getCollisionAvoidanceEnabledWithCompletion:(void (^_Nonnull)(BOOL enable, NSError *_Nullable error))completion;

/**
 *  Set vision positioning enabled. Vision positioning is used to augment GPS to
 *  improve location accuracy when hovering and improve velocity calculation
 *  when flying.
 */
- (void)setVisionPositioningEnabled:(BOOL)enable
                     withCompletion:(DJICompletionBlock)completion;

/**
 *  Get vision position enable.
 */
- (void)getVisionPositioningEnabledWithCompletion:(void (^_Nonnull)(BOOL enable, NSError *_Nullable error))completion;

/**
 *  Enables/disables precision landing. When enabled, the aircraft will record
 *  its take-off location visually (as well as with GPS). On a Return-To-Home
 *  action the aircraft will attempt to perform a precision landing using the
 *  additional visual information. This method only works on a Return-To-Home
 *  action when the home location is successfully recorded during take-off, and
 *  not changed during flight.
 *  It is supported by Phantom 4 Pro and Mavic Pro.
 *
 *  @param enabled      `YES` to enable the precise landing.
 *  @param completion   Completion block that receives the setter result.
 */
- (void)setPrecisionLandingEnabled:(BOOL)enabled withCompletion:(DJICompletionBlock)completion;

/**
 *  Gets if precision landing is enabled.
 *  It is supported by Phantom 4 Pro and Mavic Pro.
 *
 *  @param completion   Completion block that receives the getter result.
 */
- (void)getPrecisionLandingEnabledWithCompletion:(void (^_Nonnull)(BOOL enabled, NSError *_Nullable error))completion;

/**
 *  Enables/disables landing protection. During auto-landing,
 *  the downward facing vision sensor will check if the ground surface is flat
 *  enough for a safe landing. If it is not and landing proteciton is `YES`,
 *  then landing will abort and need to be manually performed
 *  by the user.
 *  It is supported by Mavic Pro, Phantom 4 Pro and Inspire 2.
 *
 *  @param enabled      `YES` to enable the landing protection.
 *  @param completion   Completion block that receives the setter result.
 */
- (void)setLandingProtectionEnabled:(BOOL)enabled withCompletion:(DJICompletionBlock)completion;

/**
 *  Gets if landing protection is enabled.
 *  It is supported by Mavic Pro, Phantom 4 Pro and Inspire 2.
 *
 *  @param completion   Completion block that receives the getter result.
 */
- (void)getLandingProtectionEnabledWithCompletion:(void (^_Nonnull)(BOOL enabled, NSError *_Nullable error))completion;

/**
 *  Enables/disables active obstacle avoidance. When enabled, and an obstacle is 
 *  moving toward the aircraft, the aircraft will actively fly away from it. If
 *  while actively avoiding a moving obstacle, the aircraft detects another obstacle
 *  in its avoidance path, it will stop.
 *  `CollisionAvoidance` must also be enabled.
 *
 *  @param enabled      `YES` to enable the active avoidance.
 *  @param completion   Completion block that receives the setter result.
 */
- (void)setActiveObstacleAvoidanceEnabled:(BOOL)enabled withCompletion:(DJICompletionBlock)completion;

/**
 *  Gets if active obstacle avoidance is enabled.
 *
 *  @param completion   Completion block that receives the getter result.
 */
- (void)getActiveObstacleAvoidanceEnabledWithCompletion:(void (^_Nonnull)(BOOL enabled, NSError *_Nullable error))completion;

/**
 *  Enables/disables upwards avoidance. When the infrared sensor on top of the
 *  Inspire 2 detects an obstacle, the aircraft will slow down the ascent speed
 *  and maintain a minimum distance (1 meter) from the obstacle. The
 *  sensor has a 10-degree horizontal field of view (FOV) and 10-degree vertical
 *  FOV. The maximum detection distance is 5 meters.
 *  It is supported by Inspire 2.
 *
 *  @param enabled      `YES` to enable the upwards avoidance.
 *  @param completion   Completion block that receives the setter result.
 */
- (void)setUpwardsAvoidanceEnabled:(BOOL)enabled withCompletion:(DJICompletionBlock)completion;

/**
 *  Gets if upwards avoidance is enabled.
 *  It is supported by Inspire 2.
 *
 *  @param completion   Completion block that receives the getter result.
 */
- (void)getUpwardsAvoidanceEnabledWithCompletion:(void (^_Nonnull)(BOOL enabled, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
