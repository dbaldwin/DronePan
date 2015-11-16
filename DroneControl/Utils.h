//
//  Utils.h
//  DronePan
//
//  Created by V Mahadev on 05/11/15.
//  Copyright © 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"
#import "global.h"

@interface Utils : NSObject

+ (void)displayToast:(UIView *)view message:(NSString *)message;

+ (void)displayToastOnApp:(NSString *)message;

+(NSDictionary *)mergeDictionaries:(NSDictionary *)lhs rhs: (NSDictionary *)rhs;

+(void) sendNotification:(NSString*)messageFrom dictionary:(NSDictionary*)dictionary;

+(void) sendNotificationWithNoteType:(NSString*)messageFrom noteType:(NoteType)noteType;

+(void) sendNotificationWithAdditionalInfo:(NSString*)messageFrom noteType:(NoteType)noteType additionalInfo:(NSDictionary*) dictionary;

@end
