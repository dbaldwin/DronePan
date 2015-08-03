//
//  DJIBattery.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJIObject.h>

@interface DJIBattery : DJIObject

/**
 *  the battery's design volume (mAh)
 */
@property(nonatomic) NSInteger designedVolume;

/**
 *  the battery's full charge volume (mAh)
 */
@property(nonatomic) NSInteger fullChargeVolume;

/**
 *   current electricity volume (mAh)
 */
@property(nonatomic) NSInteger currentElectricity;

/**
 *  voltage (mV)
 */
@property(nonatomic) NSInteger currentVoltage;

/**
 *  current (mA)
 */
@property(nonatomic) NSInteger currentCurrent;

/**
 *  remain life percentage
 */
@property(nonatomic) NSInteger remainLifePercent;

/**
 *   remain power percentage
 */
@property(nonatomic) NSInteger remainPowerPercent;

/**
 *  temperature between -128 to 127 (Centigrade)
 */
@property(nonatomic) NSInteger batteryTemperature;

/**
 *  the history discharge count
 */
@property(nonatomic) NSInteger dischargeCount;

/**
 *  update battery information
 *
 *  @param block Remote exeucte result
 */
-(void) updateBatteryInfo:(DJIExecuteResultBlock)block;

@end
