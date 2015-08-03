#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/MarkerInfoWindowViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@interface MarkerInfoWindowViewController ()<GMSMapViewDelegate>
@end

@implementation MarkerInfoWindowViewController {
  GMSMarker *_sydneyMarker;
  GMSMarker *_melbourneMarker;
  GMSMarker *_brisbaneMarker;
  UIView *_contentView;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-37.81969
                                                          longitude:144.966085
                                                               zoom:4];
  GMSMapView *mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];


  _sydneyMarker = [[GMSMarker alloc] init];
  _sydneyMarker.title = @"Sydney";
  _sydneyMarker.snippet = @"Population: 4,605,992";
  _sydneyMarker.position = CLLocationCoordinate2DMake(-33.8683, 151.2086);
  _sydneyMarker.map = mapView;
  NSLog(@"sydneyMarker: %@", _sydneyMarker);


  _melbourneMarker.map = nil;
  _melbourneMarker = [[GMSMarker alloc] init];
  _melbourneMarker.title = @"Melbourne";
  _melbourneMarker.snippet = @"Population: 4,169,103";
  _melbourneMarker.position = CLLocationCoordinate2DMake(-37.81969, 144.966085);
  _melbourneMarker.map = mapView;
  NSLog(@"melbourneMarker: %@", _melbourneMarker);

  _brisbaneMarker.map = nil;
  _brisbaneMarker = [[GMSMarker alloc] init];
  _brisbaneMarker.title = @"Brisbane";
  _brisbaneMarker.snippet = @"Population: 2,189,878";
  _brisbaneMarker.position = CLLocationCoordinate2DMake(-27.4710107, 153.0234489);
  _brisbaneMarker.map = mapView;
  NSLog(@"brisbaneMarker: %@", _brisbaneMarker);

  _contentView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"aeroplane"]];

  mapView.delegate = self;
  self.view = mapView;
}

#pragma mark GMSMapViewDelegate

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker {
  if (marker == _sydneyMarker) {
    return _contentView;
  }
  return nil;
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoContents:(GMSMarker *)marker {
  if (marker == _brisbaneMarker) {
    return _contentView;
  }
  return nil;
}

@end
