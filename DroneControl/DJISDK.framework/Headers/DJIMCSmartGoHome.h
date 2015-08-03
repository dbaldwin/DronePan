//
//  DJIMCSmartGoHome.h
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DJIMCSmartGoHomeData : NSObject

/*
 *  remainTimeForFlight
 *
 *  Discussion:
 *    The remain time in second for flight (include landing).
 *
 */
@property(nonatomic, readonly) NSUInteger remainTimeForFlight;

/*
 *  timeForGoHome
 *
 *  Discussion:
 *    The time in second that need for going to home point from current location.
 *
 */
@property(nonatomic, readonly) NSUInteger timeForGoHome;

/*
 *  timeForLanding
 *
 *  Discussion:
 *    The time in seconds that need for landing from current height.
 *
 */
@property(nonatomic, readonly) NSUInteger timeForLanding;

/*
 *  powerPercentForGoHome
 *
 *  Discussion:
 *    The power percent that need for going to home point from current location.
 *
 */
@property(nonatomic, readonly) NSUInteger powerPercentForGoHome;

/*
 *  powerPercentForLanding
 *
 *  Discussion:
 *    The power percent that need for landing from current height.
 *
 */
@property(nonatomic, readonly) NSUInteger powerPercentForLanding;

/*
 *  radiusForGoHome
 *
 *  Discussion:
 *    The max radius in meter for flight. the radius is equsl to distance form home point to drone location.
 *
 */
@property(nonatomic, readonly) float radiusForGoHome;

/*
 *  droneRequestGoHome
 *
 *  Discussion:
 *    The drone request for go home.
 *
 */
@property(nonatomic, readonly) BOOL droneRequestGoHome;

@end
