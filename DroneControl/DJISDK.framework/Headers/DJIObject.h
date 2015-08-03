//
//  DJIObject.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DJIError;

/**
 *  Remote execute result callback
 *
 *  @param error Remote execute error
 */
typedef void (^DJIExecuteResultBlock)(DJIError* error);

@interface DJIObject : NSObject

@end
