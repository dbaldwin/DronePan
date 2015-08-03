//
//  DJIMCTripodState.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJIMainControllerDef.h>

/**
 *  The aircraft's tripod state
 */
@interface DJIMCTripodState : NSObject

/**
 *  is tripod protect function opened. The tripod protect function is that the tripod will automatically put down while dron is landing.
 */
@property(nonatomic, readonly) BOOL isTripodProtectOpened;

/**
 *  Tripod status
 */
@property(nonatomic, readonly) DJIMCTripodStatus tripodStatus;

@end
