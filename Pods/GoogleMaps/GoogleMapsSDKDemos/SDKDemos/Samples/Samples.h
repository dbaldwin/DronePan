#import <Foundation/Foundation.h>

@interface Samples : NSObject
+ (NSArray *)loadSections;
+ (NSArray *)loadDemos;
+ (NSDictionary *)newDemo:(Class) class
                withTitle:(NSString *)title
           andDescription:(NSString *)description;
@end
