#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "SDKDemos/Samples/CameraViewController.h"

#import <GoogleMaps/GoogleMaps.h>

@implementation CameraViewController {
  GMSMapView *_mapView;
  NSTimer *timer;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-37.809487
                                                          longitude:144.965699
                                                               zoom:20
                                                            bearing:0
                                                       viewingAngle:0];
  _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
  _mapView.settings.zoomGestures = NO;
  _mapView.settings.scrollGestures = NO;
  _mapView.settings.rotateGestures = NO;
  _mapView.settings.tiltGestures = NO;

  self.view = _mapView;
}

- (void)moveCamera {
  GMSCameraPosition *camera = _mapView.camera;
  float zoom = fmaxf(camera.zoom - 0.1f, 17.5f);

  GMSCameraPosition *newCamera =
      [[GMSCameraPosition alloc] initWithTarget:camera.target
                                           zoom:zoom
                                        bearing:camera.bearing + 10
                                   viewingAngle:camera.viewingAngle + 10];
  [_mapView animateToCameraPosition:newCamera];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  timer = [NSTimer scheduledTimerWithTimeInterval:1.f/30.f
                                           target:self
                                         selector:@selector(moveCamera)
                                         userInfo:nil
                                          repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [timer invalidate];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  [timer invalidate];
}

@end
