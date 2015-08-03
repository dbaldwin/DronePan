//
//  DJIRangeExtender.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJIObject.h>

#define INVALID_POWER_LEVEL -1


@interface DJIRangeExtender : DJIObject

/**
 *  Get the power level of the range extender.
 *
 *  @return Power level between 0 - 10
 */
-(int) getRangeExtenderPowerLevel;

/**
 *  Bind mac address to the range extender current connected
 *
 *  @param camera's mac addrese and camera's ssid
 *
 *  @return Retrun YES if bind success.
 *  @attention If bind success, the range extender will reboot
 */
-(BOOL) bindRangeExtenderWithCameraMAC:(NSString*)macAddr cameraSSID:(NSString*)ssid;

/**
 *  Get the binding mac address of the range extender current connected
 *
 *  @return camera's mac addreess if get success.
 */
-(NSString*) getCurrentBindingMAC;

/**
 *  Get the binding ssid
 *
 *  @return bingding camera's ssid
 */
-(NSString*) getCurrentBindingSSID;

/**
 *  get MAC Address of range extender current connected
 *
 *  @return MAC address or nil if failed.
 */
-(NSString*) getMacAddressOfRangeExtender;

/**
 *  Get SSID of range extender current connected
 *
 *  @return ssid
 */
-(NSString*) getSsidOfRangeExtender;

/**
 *  Rename the extender's ssid.
 *
 *  @param newName new ssid name of range extender, must has prefix "Phantom_"
 *  @attention if rename success, the range extender will reboot
 */
-(BOOL) renameSsidOfRangeExtender:(NSString*)newSsid;

/**
 *  Get wifi password
 *
 *  @return wifi password or nil
 */
-(NSString*) getRangeExtenderWiFiPassword;

/**
 *  set wifi password
 *
 *  @param password New wifi passwords that is made up of letters and numbers and should be 8 - 16 characters。
 *                  set nil to cancel setup password
 *  @attention Hard reset range extender will clean password
 */
-(BOOL) setRangeExtenderWiFiPassword:(NSString*)password;

@end
