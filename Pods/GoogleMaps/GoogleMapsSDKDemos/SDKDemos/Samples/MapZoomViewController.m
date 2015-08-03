#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/MapZoomViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@implementation MapZoomViewController {
  GMSMapView *mapView_;
  UITextView *zoomRangeView_;
  NSUInteger nextMode_;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.868
                                                          longitude:151.2086
                                                               zoom:6];
  mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  mapView_.settings.scrollGestures = NO;
  self.view = mapView_;

  // Add a display for the current zoom range restriction.
  zoomRangeView_ = [[UITextView alloc] init];
  zoomRangeView_.frame =
      CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 0);
  zoomRangeView_.text = @"";
  zoomRangeView_.textAlignment = NSTextAlignmentCenter;
  zoomRangeView_.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8f];
  zoomRangeView_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.view addSubview:zoomRangeView_];
  [zoomRangeView_ sizeToFit];
  [self didTapNext];

  // Add a button toggling through modes.
  self.navigationItem.rightBarButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                    target:self
                                                    action:@selector(didTapNext)];
}

- (void)didTapNext {
  NSString *label = @"";
  float minZoom = kGMSMinZoomLevel;
  float maxZoom = kGMSMaxZoomLevel;

  switch (nextMode_) {
    case 0:
      label = @"Default";
      break;
    case 1:
      minZoom = 18;
      label = @"Zoomed in";
      break;
    case 2:
      maxZoom = 8;
      label = @"Zoomed out";
      break;
    case 3:
      minZoom = 10;
      maxZoom = 11.5;
      label = @"Small range";
      break;
  }
  nextMode_ = (nextMode_ + 1) % 4;

  [mapView_ setMinZoom:minZoom maxZoom:maxZoom];
  zoomRangeView_.text =
      [NSString stringWithFormat:@"%@ (%.2f - %.2f)", label, mapView_.minZoom, mapView_.maxZoom];
}

@end
