//
//  ViewController.h
//  DroneControl
//
//  Created by Dennis Baldwin on 7/9/15.
//  Copyright (c) 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DJISDK/DJISDK.h>
#import <DJISDK/DJIMainControllerDef.h>
#import "global.h"


@import GoogleMaps;



@interface ViewController : UIViewController<DJIDroneDelegate, DJIGimbalDelegate, DJICameraDelegate, GMSMapViewDelegate, DJIMainControllerDelegate, DJINavigationDelegate>
{
    
    DJIDrone *_drone;
    DJIInspireGimbal *_gimbal;
    DJIInspireCamera *_camera;
    float totalProgress;
    int totalPhotoCount;
    BOOL panoInProgress;
    DJIInspireMainController* mInspireMainController;
    
    int currentLoop;
    int yawLoopCount;
    int columnLoopCount;
    int firstLoopCount;
    int secondLoopCount;
    int thirdLoopCount;
    int fourthLoopCount;
    int droneType;
    
    int yawAngle;
    int numColumns;
    NSTimer* _readBatteryInfoTimer;
    
    CaptureMode captureMethod;
    
    dispatch_queue_t droneCmdsQueue;
    
}
//@property (assign, nonatomic) DJIDroneType droneType;
@property (nonatomic, retain) IBOutlet UIView *videoPreviewView;
@property (weak, nonatomic) IBOutlet UILabel *photoCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryRemainingLabel;
@property (weak, nonatomic) IBOutlet UILabel *altitudeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *yawLabel;
@property (weak, nonatomic) IBOutlet UILabel *pitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;
@property (weak, nonatomic) NSObject<DJINavigation>* navigation;
@property (atomic) double droneAltitude;
@property (weak, nonatomic) IBOutlet UIButton *yawAngleButton;

- (void)connectToDrone;
- (IBAction)captureMethod:(id)sender;
-(void) stopBatteryUpdate;

@end

