#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/FixedPanoramaViewController.h"

#import <GoogleMaps/GoogleMaps.h>

static CLLocationCoordinate2D kPanoramaNear = {-33.732022, 150.312114};

@interface FixedPanoramaViewController () <GMSPanoramaViewDelegate>
@end

@implementation FixedPanoramaViewController {
  GMSPanoramaView *_view;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  _view = [GMSPanoramaView panoramaWithFrame:CGRectZero
                              nearCoordinate:kPanoramaNear];
  _view.camera = [GMSPanoramaCamera cameraWithHeading:180
                                                pitch:-10
                                                 zoom:0];
  _view.delegate = self;
  _view.orientationGestures = NO;
  _view.navigationGestures = NO;
  _view.navigationLinksHidden = YES;
  self.view = _view;
}

@end
