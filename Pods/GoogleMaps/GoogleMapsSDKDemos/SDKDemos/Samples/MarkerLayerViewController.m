#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/MarkerLayerViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@interface CoordsList : NSObject
@property(nonatomic, readonly, copy) GMSPath *path;
@property(nonatomic, readonly) NSUInteger target;

- (id)initWithPath:(GMSPath *)path;

- (CLLocationCoordinate2D)next;

@end

@implementation CoordsList

- (id)initWithPath:(GMSPath *)path {
  if ((self = [super init])) {
    _path = [path copy];
    _target = 0;
  }
  return self;
}

- (CLLocationCoordinate2D)next {
  ++_target;
  if (_target == [_path count]) {
    _target = 0;
  }
  return [_path coordinateAtIndex:_target];
}

@end

@implementation MarkerLayerViewController {
  GMSMapView *mapView_;
  GMSMarker *fadedMarker_;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  mapView_ = [[GMSMapView alloc] init];
  mapView_.camera = [GMSCameraPosition cameraWithLatitude:50.6042 longitude:3.9599 zoom:5];
  mapView_.delegate = self;
  self.view = mapView_;

  GMSMutablePath *coords;
  GMSMarker *marker;

  // Create a plane that flies to several airports around western Europe.
  coords = [GMSMutablePath path];
  [coords addLatitude:52.310683 longitude:4.765121];
  [coords addLatitude:51.471386 longitude:-0.457148];
  [coords addLatitude:49.01378 longitude:2.5542943];
  [coords addLatitude:50.036194 longitude:8.554519];
  marker = [GMSMarker markerWithPosition:[coords coordinateAtIndex:0]];
  marker.icon = [UIImage imageNamed:@"aeroplane"];
  marker.groundAnchor = CGPointMake(0.5f, 0.5f);
  marker.flat = YES;
  marker.map = mapView_;
  marker.userData = [[CoordsList alloc] initWithPath:coords];
  [self animateToNextCoord:marker];

  // Create a boat that moves around the Baltic Sea.
  coords = [GMSMutablePath path];
  [coords addLatitude:57.598335 longitude:11.290512];
  [coords addLatitude:55.665193 longitude:10.741196];
  [coords addLatitude:55.065787 longitude:11.083488];
  [coords addLatitude:54.699234 longitude:10.863762];
  [coords addLatitude:54.482805 longitude:12.061272];
  [coords addLatitude:55.819802 longitude:16.148186];  // final point
  [coords addLatitude:54.927142 longitude:16.455803];  // final point
  [coords addLatitude:54.482805 longitude:12.061272];  // and back again
  [coords addLatitude:54.699234 longitude:10.863762];
  [coords addLatitude:55.065787 longitude:11.083488];
  [coords addLatitude:55.665193 longitude:10.741196];
  marker = [GMSMarker markerWithPosition:[coords coordinateAtIndex:0]];
  marker.icon = [UIImage imageNamed:@"boat"];
  marker.map = mapView_;
  marker.userData = [[CoordsList alloc] initWithPath:coords];
  [self animateToNextCoord:marker];
}

- (void)animateToNextCoord:(GMSMarker *)marker {
  CoordsList *coords = marker.userData;
  CLLocationCoordinate2D coord = [coords next];
  CLLocationCoordinate2D previous = marker.position;

  CLLocationDirection heading = GMSGeometryHeading(previous, coord);
  CLLocationDistance distance = GMSGeometryDistance(previous, coord);

  // Use CATransaction to set a custom duration for this animation. By default, changes to the
  // position are already animated, but with a very short default duration. When the animation is
  // complete, trigger another animation step.

  [CATransaction begin];
  [CATransaction setAnimationDuration:(distance / (50 * 1000))];  // custom duration, 50km/sec

  __weak MarkerLayerViewController *weakSelf = self;
  [CATransaction setCompletionBlock:^{
    [weakSelf animateToNextCoord:marker];
  }];

  marker.position = coord;

  [CATransaction commit];

  // If this marker is flat, implicitly trigger a change in rotation, which will finish quickly.
  if (marker.flat) {
    marker.rotation = heading;
  }
}

- (void)fadeMarker:(GMSMarker *)marker {
  fadedMarker_.opacity = 1.0f;  // reset previous faded marker

  // Fade this new marker.
  fadedMarker_ = marker;
  fadedMarker_.opacity = 0.5f;
}

#pragma mark - GMSMapViewDelegate

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
  [self fadeMarker:marker];
  return YES;
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
  [self fadeMarker:nil];
}

@end
