//
//  Utils.h
//  DronePan
//
//  Created by Dennis Baldwin on 3/10/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@interface Utils : NSObject

+ (void)displayToast:(UIView *)view message:(NSString *)message;
+ (void)displayToastOnApp:(NSString *)message;

@end
