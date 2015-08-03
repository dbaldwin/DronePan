//
//  DJIInspireBattery.h
//  DJISDK
//
//  Copyright (c) 2015 DJI. All rights reserved.
//

#import <DJISDK/DJIBattery.h>

@interface DJIBatteryState : NSObject
/**
 *  Over current in discharge
 */
@property(nonatomic, readonly) BOOL dischargeOverCurrent;
/**
 *  Over heat in discharge
 */
@property(nonatomic, readonly) BOOL dischargeOverHeat;
/**
 *  Low temperature in discharge.
 */
@property(nonatomic, readonly) BOOL dischargeLowTemperature;
/**
 *  Short cut in discharge
 */
@property(nonatomic, readonly) BOOL dischargeShortCut;
/**
 *  Self-discharge in storage
 */
@property(nonatomic, readonly) BOOL selfDischarge;
/**
 *  Cell Under voltage
 */
@property(nonatomic, readonly) uint8_t underVoltageCellIndex;
/**
 *  Cell damaged
 */
@property(nonatomic, readonly) uint8_t damagedCellIndex;

@end

@interface DJIBatteryCell : NSObject

/**
 *  Cell voltage
 */
@property(nonatomic, readonly) uint16_t voltage;

-(id) initWithVolgate:(uint16_t)voltage;

@end

@interface DJIInspireBattery : DJIBattery

/**
 *  Get battery history state
 *
 *  @param result Remote execute result.
 */
-(void) getBatteryHistoryState:(void(^)(NSArray* history, DJIError* error))result;

/**
 *  Get battery current state
 *
 *  @param result Remote execute result.
 */
-(void) getBatteryCurrentState:(void (^)(DJIBatteryState* state, DJIError *))result;

/**
 *  Set battery self-discharge day.
 *
 *  @param day    Day of self-discharge
 *  @param result Remote execute result
 */
-(void) setBatterySelfDischargeDay:(uint8_t)day withResult:(DJIExecuteResultBlock)result;

/**
 *  Get battery self-discharge day
 *
 *  @param result Remote execute result
 */
-(void) getBatterySelfDischargeDayWithResult:(void(^)(uint8_t day, DJIError* error))result;

/**
 *  Get cell's voltage. The object in cellArray is type of class DJIBatteryCell
 *
 *  @param block Remote execute result
 */
-(void) getCellVoltagesWithResult:(void(^)(NSArray* cellArray, DJIError* error))block;

@end
