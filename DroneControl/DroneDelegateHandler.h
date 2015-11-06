//
//  DroneDelegateHandler.h
//  DronePan
//
//  Created by V Mahadev on 06/11/15.
//  Copyright © 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DJISDK/DJISDK.h>
#import <DJISDK/DJIMainControllerDef.h>
#import "Utils.h"

@interface DroneDelegateHandler : NSObject<DJIDroneDelegate,DJIGimbalDelegate,DJICameraDelegate,DJIMainControllerDelegate,DJINavigationDelegate>

@end
