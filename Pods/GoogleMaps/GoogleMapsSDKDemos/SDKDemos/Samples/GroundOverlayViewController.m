#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/GroundOverlayViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@implementation GroundOverlayViewController {
  GMSGroundOverlay *overlay_;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  CLLocationCoordinate2D southWest = CLLocationCoordinate2DMake(40.712216, -74.22655);
  CLLocationCoordinate2D northEast = CLLocationCoordinate2DMake(40.773941, -74.12544);

  GMSCoordinateBounds *overlayBounds = [[GMSCoordinateBounds alloc] initWithCoordinate:southWest
                                                                            coordinate:northEast];

  // Choose the midpoint of the coordinate to focus the camera on.
  CLLocationCoordinate2D newark = GMSGeometryInterpolate(southWest, northEast, 0.5);
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithTarget:newark
                                                             zoom:12
                                                          bearing:0
                                                     viewingAngle:45];
  GMSMapView *mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];

  // Add the ground overlay, centered in Newark, NJ
  GMSGroundOverlay *groundOverlay = [[GMSGroundOverlay alloc] init];
  // Image from http://www.lib.utexas.edu/maps/historical/newark_nj_1922.jpg
  groundOverlay.icon = [UIImage imageNamed:@"newark_nj_1922.jpg"];
  groundOverlay.position = newark;
  groundOverlay.bounds = overlayBounds;
  groundOverlay.map = mapView;

  self.view = mapView;
}

@end
