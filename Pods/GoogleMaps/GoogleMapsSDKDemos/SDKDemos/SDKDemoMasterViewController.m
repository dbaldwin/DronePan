#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/SDKDemoMasterViewController.h"

#import "SDKDemos/PlacesSamples/Samples+Places.h"
#import "SDKDemos/SDKDemoAppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import "SDKDemos/Samples/Samples.h"

@implementation SDKDemoMasterViewController {
  NSArray *demos_;
  NSArray *demoSections_;
  BOOL isPhone_;
  UIPopoverController *popover_;
  UIBarButtonItem *samplesButton_;
  __weak UIViewController *controller_;
  CLLocationManager *locationManager_;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  isPhone_ = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;

  if (!isPhone_) {
    self.clearsSelectionOnViewWillAppear = NO;
  } else {
    UIBarButtonItem *backButton =
    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"Back")
                                     style:UIBarButtonItemStyleBordered
                                    target:nil
                                    action:nil];
    [self.navigationItem setBackBarButtonItem:backButton];
  }

  self.title = NSLocalizedString(@"Maps SDK Demos", @"Maps SDK Demos");
  self.title = [NSString stringWithFormat:@"%@: %@", self.title, [GMSServices SDKVersion]];

  self.tableView.autoresizingMask =
      UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
  self.tableView.delegate = self;
  self.tableView.dataSource = self;

  demoSections_ = [Samples loadSections];
  demos_ = [Samples loadDemos];
  [self addPlacesDemos];

  if (!isPhone_) {
    [self loadDemo:0 atIndex:0];
  }
}
- (void)addPlacesDemos {
  NSMutableArray *sections = [NSMutableArray arrayWithArray:demoSections_];
  [sections insertObject:@"Places" atIndex:0];
  demoSections_ = [sections copy];

  NSMutableArray *demos = [NSMutableArray arrayWithArray:demos_];
  [demos insertObject:[Samples placesDemos]
              atIndex:0];
  demos_ = [demos copy];
}

#pragma mark - UITableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return demoSections_.count;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForHeaderInSection:(NSInteger)section {
  return 35.0;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  return [demoSections_ objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return [[demos_ objectAtIndex: section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIdentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                  reuseIdentifier:cellIdentifier];

    if (isPhone_) {
      [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
  }

  NSDictionary *demo = [[demos_ objectAtIndex:indexPath.section]
                        objectAtIndex:indexPath.row];
  cell.textLabel.text = [demo objectForKey:@"title"];
  cell.detailTextLabel.text = [demo objectForKey:@"description"];

  return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // The user has chosen a sample; load it and clear the selection!
  [self loadDemo:indexPath.section atIndex:indexPath.row];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController
     willHideViewController:(UIViewController *)viewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)popoverController {
  popover_ = popoverController;
  samplesButton_ = barButtonItem;
  samplesButton_.title = NSLocalizedString(@"Samples", @"Samples");
  samplesButton_.style = UIBarButtonItemStyleDone;
  [self updateSamplesButton];
}

- (void)splitViewController:(UISplitViewController *)splitController
       willShowViewController:(UIViewController *)viewController
    invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
  popover_ = nil;
  samplesButton_ = nil;
  [self updateSamplesButton];
}

#pragma mark - Private methods

- (void)loadDemo:(NSUInteger)section
         atIndex:(NSUInteger)index {
  NSDictionary *demo = [[demos_ objectAtIndex:section] objectAtIndex:index];
  UIViewController *controller =
      [[[demo objectForKey:@"controller"] alloc] init];
  controller_ = controller;

  if (controller != nil) {
    controller.title = [demo objectForKey:@"title"];

    if (isPhone_) {
      [self.navigationController pushViewController:controller animated:YES];
    } else {
      [self.appDelegate setSample:controller];
      [popover_ dismissPopoverAnimated:YES];
    }

    [self updateSamplesButton];
  }
}

// This method is invoked when the left 'back' button in the split view
// controller on iPad should be updated (either made visible or hidden).
// It assumes that the left bar button item may be safely modified to contain
// the samples button.
- (void)updateSamplesButton {
  controller_.navigationItem.leftBarButtonItem = samplesButton_;
}

@end
