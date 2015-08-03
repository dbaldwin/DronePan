#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/IndoorViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@implementation IndoorViewController {
  GMSMapView *mapView_;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:37.78318
                                                          longitude:-122.403874
                                                               zoom:18];

  mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  mapView_.settings.myLocationButton = YES;

  self.view = mapView_;
}


@end
