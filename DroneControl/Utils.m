//
//  Utils.m
//  DronePan
//
//  Created by V Mahadev on 05/11/15.
//  Copyright © 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (void)displayToast:(UIView *)view message:(NSString *)message{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.color = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = message;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:5];
}
@end
