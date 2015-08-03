#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/GradientPolylinesViewController.h"

#import <GoogleMaps/GoogleMaps.h>


@implementation GradientPolylinesViewController {
  GMSMapView *mapView_;
  GMSPolyline *polyline_;
  NSMutableArray *trackData_;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:44.1314
                                                          longitude:9.6921
                                                               zoom:14.059f
                                                            bearing:328.f
                                                       viewingAngle:40.f];
  mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  self.view = mapView_;

  [self parseTrackFile];
  [polyline_ setSpans:[self gradientSpans]];
}

- (NSArray *)gradientSpans {
  NSMutableArray *colorSpans = [NSMutableArray array];
  NSUInteger count = [trackData_ count];
  UIColor *prevColor;
  for (NSUInteger i = 0; i < count; i++) {
    double elevation = [[[trackData_ objectAtIndex:i] objectForKey:@"elevation"] doubleValue];

    UIColor *toColor = [UIColor colorWithHue:(float)elevation/700
                                  saturation:1.f
                                  brightness:.9f
                                       alpha:1.f];

    if (prevColor == nil) {
      prevColor = toColor;
    }

    GMSStrokeStyle *style = [GMSStrokeStyle gradientFromColor:prevColor toColor:toColor];
    [colorSpans addObject:[GMSStyleSpan spanWithStyle:style]];

    prevColor = toColor;
  }
  return colorSpans;
}

- (void)parseTrackFile {
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"track" ofType:@"json"];
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  NSArray *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
  trackData_ = [[NSMutableArray alloc] init];
  GMSMutablePath *path = [GMSMutablePath path];

  for (NSUInteger i = 0; i < [json count]; i++) {
    NSDictionary *info = [json objectAtIndex:i];
    NSNumber *elevation = [info objectForKey:@"elevation"];
    CLLocationDegrees lat = [[info objectForKey:@"lat"] doubleValue];
    CLLocationDegrees lng = [[info objectForKey:@"lng"] doubleValue];
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
    [trackData_ addObject:@{@"loc": loc, @"elevation": elevation}];
    [path addLatitude:lat longitude:lng];
  }

  polyline_ = [GMSPolyline polylineWithPath:path];
  polyline_.strokeWidth = 6;
  polyline_.map = mapView_;
}

@end
