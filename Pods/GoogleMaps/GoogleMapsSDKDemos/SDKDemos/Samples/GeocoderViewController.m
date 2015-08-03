#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/GeocoderViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@implementation GeocoderViewController {
  GMSMapView *mapView_;
  GMSGeocoder *geocoder_;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.868
                                                          longitude:151.2086
                                                               zoom:12];

  mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  mapView_.delegate = self;

  geocoder_ = [[GMSGeocoder alloc] init];

  self.view = mapView_;
}

- (void)mapView:(GMSMapView *)mapView
    didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
  // On a long press, reverse geocode this location.
  GMSReverseGeocodeCallback handler = ^(GMSReverseGeocodeResponse *response, NSError *error) {
    GMSAddress *address = response.firstResult;
    if (address) {
      NSLog(@"Geocoder result: %@", address);

      GMSMarker *marker = [GMSMarker markerWithPosition:address.coordinate];

      marker.title = [[address lines] firstObject];
      if ([[address lines] count] > 1) {
        marker.snippet = [[address lines] objectAtIndex:1];
      }

      marker.appearAnimation = kGMSMarkerAnimationPop;
      marker.map = mapView_;
    } else {
      NSLog(@"Could not reverse geocode point (%f,%f): %@",
            coordinate.latitude, coordinate.longitude, error);
    }
  };
  [geocoder_ reverseGeocodeCoordinate:coordinate completionHandler:handler];
}

@end
