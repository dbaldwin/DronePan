#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/CustomMarkersViewController.h"

#import <GoogleMaps/GoogleMaps.h>

static int kMarkerCount = 0;

// Returns a random value from 0-1.0f.
static CGFloat randf() {
  return (((float)arc4random()/0x100000000)*1.0f);
}

@implementation CustomMarkersViewController {
  GMSMapView *_mapView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-37.81969
                                                          longitude:144.966085
                                                               zoom:4];
  _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  [self addDefaultMarkers];

  // Add a button which adds random markers to the map.
  UIBarButtonItem *addButton =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                    target:self
                                                    action:@selector(didTapAdd)];
  addButton.accessibilityLabel = @"Add Markers";
  UIBarButtonItem *clearButton =
      [[UIBarButtonItem alloc] initWithTitle:@"Clear Markers"
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(didTapClear)];
  self.navigationItem.rightBarButtonItems = @[ addButton, clearButton ];

  self.view = _mapView;
}

- (void)addDefaultMarkers {
  // Add a custom 'glow' marker around Sydney.
  GMSMarker *sydneyMarker = [[GMSMarker alloc] init];
  sydneyMarker.title = @"Sydney!";
  sydneyMarker.icon = [UIImage imageNamed:@"glow-marker"];
  sydneyMarker.position = CLLocationCoordinate2DMake(-33.8683, 151.2086);
  sydneyMarker.map = _mapView;

  // Add a custom 'arrow' marker pointing to Melbourne.
  GMSMarker *melbourneMarker = [[GMSMarker alloc] init];
  melbourneMarker.title = @"Melbourne!";
  melbourneMarker.icon = [UIImage imageNamed:@"arrow"];
  melbourneMarker.position = CLLocationCoordinate2DMake(-37.81969, 144.966085);
  melbourneMarker.map = _mapView;
}

- (void)didTapAdd {
  for (int i = 0; i < 10; ++i) {
    // Add a marker every 0.25 seconds for the next ten markers, randomly
    // within the bounds of the camera as it is at that point.
    double delayInSeconds = (i * 0.25);
    dispatch_time_t popTime =
        dispatch_time(DISPATCH_TIME_NOW,
                      (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
      GMSVisibleRegion region = [_mapView.projection visibleRegion];
      GMSCoordinateBounds *bounds =
          [[GMSCoordinateBounds alloc] initWithRegion:region];
      [self addMarkerInBounds:bounds];
    });
  }
}

- (void)addMarkerInBounds:(GMSCoordinateBounds *)bounds {
  CLLocationDegrees latitude = bounds.southWest.latitude +
      randf() * (bounds.northEast.latitude - bounds.southWest.latitude);

  // If the visible region crosses the antimeridian (the right-most point is
  // "smaller" than the left-most point), adjust the longitude accordingly.
  BOOL offset = (bounds.northEast.longitude < bounds.southWest.longitude);
  CLLocationDegrees longitude = bounds.southWest.longitude + randf() *
      (bounds.northEast.longitude - bounds.southWest.longitude + (offset ?
                                                                  360 : 0));
  if (longitude > 180.f) {
    longitude -= 360.f;
  }

  UIColor *color =
      [UIColor colorWithHue:randf() saturation:1.f brightness:1.f alpha:1.0f];

  CLLocationCoordinate2D position =
      CLLocationCoordinate2DMake(latitude, longitude);
  GMSMarker *marker = [GMSMarker markerWithPosition:position];
  marker.title = [NSString stringWithFormat:@"Marker #%d", ++kMarkerCount];
  marker.appearAnimation = kGMSMarkerAnimationPop;
  marker.icon = [GMSMarker markerImageWithColor:color];

  marker.rotation = (randf()-0.5f)*20;  // rotate between -20 and +20 degrees

  marker.map = _mapView;
}

- (void)didTapClear {
  [_mapView clear];
  [self addDefaultMarkers];
}

@end
