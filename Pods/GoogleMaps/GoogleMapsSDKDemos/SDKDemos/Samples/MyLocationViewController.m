#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/MyLocationViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@implementation MyLocationViewController {
  GMSMapView *mapView_;
  BOOL firstLocationUpdate_;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.868
                                                          longitude:151.2086
                                                               zoom:12];

  mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  mapView_.settings.compassButton = YES;
  mapView_.settings.myLocationButton = YES;

  // Listen to the myLocation property of GMSMapView.
  [mapView_ addObserver:self
             forKeyPath:@"myLocation"
                options:NSKeyValueObservingOptionNew
                context:NULL];

  self.view = mapView_;

  // Ask for My Location data after the map has already been added to the UI.
  dispatch_async(dispatch_get_main_queue(), ^{
    mapView_.myLocationEnabled = YES;
  });
}

- (void)dealloc {
  [mapView_ removeObserver:self
                forKeyPath:@"myLocation"
                   context:NULL];
}

#pragma mark - KVO updates

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  if (!firstLocationUpdate_) {
    // If the first location update has not yet been recieved, then jump to that
    // location.
    firstLocationUpdate_ = YES;
    CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
    mapView_.camera = [GMSCameraPosition cameraWithTarget:location.coordinate
                                                     zoom:14];
  }
}

@end
