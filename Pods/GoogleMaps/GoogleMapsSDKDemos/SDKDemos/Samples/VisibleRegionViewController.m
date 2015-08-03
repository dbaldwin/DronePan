#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/VisibleRegionViewController.h"

#import <GoogleMaps/GoogleMaps.h>

static CGFloat kOverlayHeight = 140.0f;

@implementation VisibleRegionViewController {
  GMSMapView *_mapView;
  UIView *_overlay;
  UIBarButtonItem *_flyInButton;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-37.81969
                                                          longitude:144.966085
                                                               zoom:4];
  _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];

  // Enable my location button to show more UI components updating.
  _mapView.settings.myLocationButton = YES;
  _mapView.myLocationEnabled = YES;
  _mapView.padding = UIEdgeInsetsMake(0, 0, kOverlayHeight, 0);
  self.view = _mapView;

  // Create a button that, when pressed, causes an overlaying view to fly-in/out.
  _flyInButton = [[UIBarButtonItem alloc] initWithTitle:@"Toggle Overlay"
                                                  style:UIBarButtonItemStylePlain
                                                 target:self
                                                 action:@selector(didTapFlyIn)];
  self.navigationItem.rightBarButtonItem = _flyInButton;

  CGRect overlayFrame = CGRectMake(0, -kOverlayHeight, 0, kOverlayHeight);
  _overlay = [[UIView alloc] initWithFrame:overlayFrame];
  _overlay.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;

  _overlay.backgroundColor = [UIColor colorWithHue:0.0 saturation:1.0 brightness:1.0 alpha:0.5];
  [self.view addSubview:_overlay];
}

- (void)didTapFlyIn {
  UIEdgeInsets padding = _mapView.padding;

  [UIView animateWithDuration:2.0 animations:^{
    CGSize size = self.view.bounds.size;
    if (padding.bottom == 0.0f) {
      _overlay.frame = CGRectMake(0, size.height - kOverlayHeight, size.width, kOverlayHeight);
      _mapView.padding = UIEdgeInsetsMake(0, 0, kOverlayHeight, 0);
    } else {
      _overlay.frame = CGRectMake(0, _mapView.bounds.size.height, size.width, 0);
      _mapView.padding = UIEdgeInsetsZero;
    }
  }];
}

@end
