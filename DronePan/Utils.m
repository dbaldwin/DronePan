/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
+(void)displayToastOnApp:(NSString *)message{
    dispatch_async(dispatch_get_main_queue(), ^{
        if([UIApplication sharedApplication].keyWindow.rootViewController.view!=nil) {
            [Utils displayToast:[UIApplication sharedApplication].keyWindow.rootViewController.view message:message];
        }
    });
}

@end
