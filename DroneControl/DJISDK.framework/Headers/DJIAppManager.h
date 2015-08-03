//
//  DJIAppManager.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJIFoundation.h>

///Register App Error Code
#define RegisterSuccess                   0
#define RegisterErrorConnectInternet     -1
#define RegisterErrorInvalidAppKey       -2
#define RegisterErrorGetMetaDataTimeout  -3
#define RegisterErrorDeviceNotMatch      -4
#define RegisterErrorBundleIdNotMatch    -5
#define RegisterErrorAppKeyProhibited    -6
#define RegisterErrorActivationExceed    -7
#define RegisterErrorAppKeyPlatformError -8
#define RegisterErrorAppKeyNotExist      -9
#define RegisterErrorAppKeyNoPermission  -10
#define RegisterErrorServerParseFailure  -11
#define RegisterErrorServerWriteError    -12
#define RegisterErrorServerDataAbnormal  -13
#define RegisterErrorInvalidMetaData     -14

#define RegisterErrorUnknown             -1000

@protocol DJIAppManagerDelegate <NSObject>

/**
 *  Register result
 */
-(void) appManagerDidRegisterWithError:(int)errorCode;

@end

@interface DJIAppManager : NSObject

/**
 *  Register app from server. User should call once while app started and should connect to the internet at the first time registration.
 *
 *  @param appKey   App key
 *  @param delegate Register result callback
 */
+(void) registerApp:(NSString*)appKey withDelegate:(id<DJIAppManagerDelegate>)delegate;

/**
 *  Get register error descryption
 *
 *  @param errorCode Error code from regist app
 *
 *  @return Error descryption
 */
+(NSString*) getErrorDescryption:(int)errorCode;

/**
 *  Get DJI SDK framework version
 *
 *  @return Version
 */
+(NSString*) getFrameworkVersion;

@end
