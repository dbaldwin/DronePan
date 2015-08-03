#import <UIKit/UIKit.h>

@class SDKDemoAppDelegate;

@interface SDKDemoMasterViewController : UITableViewController <
    UISplitViewControllerDelegate,
    UITableViewDataSource,
    UITableViewDelegate>

@property(nonatomic, assign) SDKDemoAppDelegate *appDelegate;

@end
