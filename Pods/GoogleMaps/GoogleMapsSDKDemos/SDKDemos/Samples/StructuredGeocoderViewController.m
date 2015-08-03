#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/StructuredGeocoderViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@interface StructuredGeocoderViewController () <GMSMapViewDelegate>

@end

@implementation StructuredGeocoderViewController {
  GMSMapView *_mapView;
  GMSGeocoder *_geocoder;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.868
                                                          longitude:151.2086
                                                               zoom:12];

  _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  _mapView.delegate = self;

  _geocoder = [[GMSGeocoder alloc] init];

  self.view = _mapView;
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView
    didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
  // On a long press, reverse geocode this location.
  GMSReverseGeocodeCallback handler = ^(GMSReverseGeocodeResponse *response, NSError *error) {
    GMSAddress *address = response.firstResult;
    if (address) {
      NSLog(@"Geocoder result: %@", address);

      GMSMarker *marker = [GMSMarker markerWithPosition:address.coordinate];

      marker.title = address.thoroughfare;

      NSMutableString *snippet = [[NSMutableString alloc] init];
      if (address.subLocality != NULL) {
        [snippet appendString:[NSString stringWithFormat:@"subLocality: %@\n",
                               address.subLocality]];
      }
      if (address.locality != NULL) {
        [snippet appendString:[NSString stringWithFormat:@"locality: %@\n",
                               address.locality]];
      }
      if (address.administrativeArea != NULL) {
        [snippet appendString:[NSString stringWithFormat:@"administrativeArea: %@\n",
                               address.administrativeArea]];
      }
      if (address.country != NULL) {
        [snippet appendString:[NSString stringWithFormat:@"country: %@\n",
                               address.country]];
      }

      marker.snippet = snippet;

      marker.appearAnimation = kGMSMarkerAnimationPop;
      mapView.selectedMarker = marker;
      marker.map = _mapView;
    } else {
      NSLog(@"Could not reverse geocode point (%f,%f): %@",
            coordinate.latitude, coordinate.longitude, error);
    }
  };
  [_geocoder reverseGeocodeCoordinate:coordinate completionHandler:handler];
}

@end
