#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/IndoorMuseumNavigationViewController.h"

@implementation IndoorMuseumNavigationViewController {
  GMSMapView *mapView_;
  NSArray *exhibits_;     // Array of JSON exhibit data.
  NSDictionary *exhibit_; // The currently selected exhibit. Will be nil initially.
  GMSMarker *marker_;
  NSDictionary *levels_;  // The levels dictionary is updated when a new building is selected, and
                          // contains mapping from localized level name to GMSIndoorLevel.
}

- (void)viewDidLoad {
  [super viewDidLoad];

  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:38.8879
                                                          longitude:-77.0200
                                                               zoom:17];
  mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  mapView_.settings.myLocationButton = NO;
  mapView_.settings.indoorPicker = NO;
  mapView_.delegate = self;
  mapView_.indoorDisplay.delegate = self;

  self.view = mapView_;

  // Load the exhibits configuration from JSON
  NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"museum-exhibits" ofType:@"json"];
  NSData *data = [NSData dataWithContentsOfFile:jsonPath];
  exhibits_ = [NSJSONSerialization JSONObjectWithData:data
                                              options:kNilOptions
                                                error:nil];


  UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] init];
  [segmentedControl setTintColor:[UIColor colorWithRed:0.373f green:0.667f blue:0.882f alpha:1.0f]];

  segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
  [segmentedControl addTarget:self
                       action:@selector(exhibitSelected:)
             forControlEvents:UIControlEventValueChanged];
  [self.view addSubview:segmentedControl];

  for (NSDictionary *exhibit in exhibits_) {
    [segmentedControl insertSegmentWithImage:[UIImage imageNamed:exhibit[@"key"]]
                                     atIndex:[exhibits_ indexOfObject:exhibit]
                                    animated:NO];
  }

  NSDictionary *views = NSDictionaryOfVariableBindings(segmentedControl);

  [self.view addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"[segmentedControl]-|"
                             options:kNilOptions
                             metrics:nil
                             views:views]];
  [self.view addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"V:[segmentedControl]-|"
                             options:kNilOptions
                             metrics:nil
                             views:views]];

}

- (void)moveMarker {
  CLLocationCoordinate2D loc = CLLocationCoordinate2DMake([exhibit_[@"lat"] doubleValue],
                                                          [exhibit_[@"lng"] doubleValue]);
  if (marker_ == nil) {
    marker_ = [GMSMarker markerWithPosition:loc];
    marker_.map = mapView_;
  } else {
    marker_.position = loc;
  }
  marker_.title = exhibit_[@"name"];
  [mapView_ animateToLocation:loc];
  [mapView_ animateToZoom:19];
}

- (void)exhibitSelected:(UISegmentedControl *)segmentedControl {
  exhibit_ = exhibits_[[segmentedControl selectedSegmentIndex]];
  [self moveMarker];
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)camera {
  if (exhibit_ != nil) {
    CLLocationCoordinate2D loc = CLLocationCoordinate2DMake([exhibit_[@"lat"] doubleValue],
                                                            [exhibit_[@"lng"] doubleValue]);
    if ([mapView_.projection containsCoordinate:loc] && levels_ != nil) {
      [mapView.indoorDisplay setActiveLevel:levels_[exhibit_[@"level"]]];
    }
  }
}

#pragma mark - GMSIndoorDisplayDelegate

- (void)didChangeActiveBuilding:(GMSIndoorBuilding *)building {
  if (building != nil) {
    NSMutableDictionary *levels = [NSMutableDictionary dictionary];

    for (GMSIndoorLevel *level in building.levels) {
      [levels setObject:level forKey:level.shortName];
    }

    levels_ = [NSDictionary dictionaryWithDictionary:levels];
  } else {
    levels_ = nil;
  }
}

@end
