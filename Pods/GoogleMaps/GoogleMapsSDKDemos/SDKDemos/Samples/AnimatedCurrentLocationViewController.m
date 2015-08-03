#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/AnimatedCurrentLocationViewController.h"

@implementation AnimatedCurrentLocationViewController {
  CLLocationManager *_manager;
  GMSMapView        *_mapView;
  GMSMarker         *_locationMarker;

}

- (void)viewDidLoad {
  [super viewDidLoad];

  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:38.8879
                                                          longitude:-77.0200
                                                               zoom:17];
  _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  _mapView.settings.myLocationButton = NO;
  _mapView.settings.indoorPicker = NO;

  self.view = _mapView;

  // Setup location services
  if (![CLLocationManager locationServicesEnabled]) {
    NSLog(@"Please enable location services");
    return;
  }

  if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
    NSLog(@"Please authorize location services");
    return;
  }

  _manager = [[CLLocationManager alloc] init];
  _manager.delegate = self;
  _manager.desiredAccuracy = kCLLocationAccuracyBest;
  _manager.distanceFilter = 5.0f;
  [_manager startUpdatingLocation];

}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
    NSLog(@"Please authorize location services");
    return;
  }

  NSLog(@"CLLocationManager error: %@", error.localizedFailureReason);
  return;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
  CLLocation *location = [locations lastObject];

  if (_locationMarker == nil) {
    _locationMarker = [[GMSMarker alloc] init];
    _locationMarker.position = CLLocationCoordinate2DMake(-33.86, 151.20);

    // Animated walker images derived from an www.angryanimator.com tutorial.
    // See: http://www.angryanimator.com/word/2010/11/26/tutorial-2-walk-cycle/

    NSArray *frames = @[[UIImage imageNamed:@"step1"],
                        [UIImage imageNamed:@"step2"],
                        [UIImage imageNamed:@"step3"],
                        [UIImage imageNamed:@"step4"],
                        [UIImage imageNamed:@"step5"],
                        [UIImage imageNamed:@"step6"],
                        [UIImage imageNamed:@"step7"],
                        [UIImage imageNamed:@"step8"]];

    _locationMarker.icon = [UIImage animatedImageWithImages:frames duration:0.8];
    _locationMarker.groundAnchor = CGPointMake(0.5f, 0.97f); // Taking into account walker's shadow
    _locationMarker.map = _mapView;
  } else {
    [CATransaction begin];
    [CATransaction setAnimationDuration:2.0];
    _locationMarker.position = location.coordinate;
    [CATransaction commit];
  }

  GMSCameraUpdate *move = [GMSCameraUpdate setTarget:location.coordinate zoom:17];
  [_mapView animateWithCameraUpdate:move];
}


@end
