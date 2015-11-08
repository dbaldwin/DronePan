//
//  ViewController.m
//  DroneControl
//
//  Created by Dennis Baldwin on 7/9/15.
//  Copyright (c) 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import "ViewController.h"
#import "VideoPreviewer.h"
#import "MBProgressHUD.h"
#import "utils.h"
#import <DJISDK/DJISDK.h>

#define stopPanoTag 100
#define captureMethodTag 200
#define yawAngleTag 300

// Yaw angles
// 30 12 rotations
// 45 8 rotations
// 60 6 rotations

@interface ViewController () {
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Temp test for widths of status indicators
    /*self.photoCountLabel.text = @"Photo: 20/20";
     self.batteryRemainingLabel.text = @"Battery: 100%";
     self.altitudeLabel.text = @"Alt: 200m";
     self.yawLabel.text = @"Yaw: 180";
     self.pitchLabel.text = @"Pitch: -90";*/
    
    
    
    [self.progressView setTransform:CGAffineTransformMakeScale(1.0, 100.0)];
    
    self.progressView.progress = 0;
    
    panoInProgress = NO;
    
    firstLoopCount = secondLoopCount = thirdLoopCount = fourthLoopCount = 0;
    
    currentLoop = 1;
    
    yawLoopCount = 0;
    
    columnLoopCount = 0;
    
    // Variables for yaw angle
    yawAngle = 60; // 60 is our default yaw angle
    numColumns = 6; // We take 6 columns or 6 rotations of photos by default
    
    // By default we'll use the yaw aircraft capture method
    captureMethod = 1;
    
}

-(void) viewWillAppear:(BOOL)animated {
   
    [super viewWillAppear:animated];
    [_drone connectToDrone];
    [_drone.mainController startUpdateMCSystemState];
    [[VideoPreviewer instance] setView:self.videoPreviewView];
}

-(void) viewDidAppear:(BOOL)animated {
    // Check to see if this is the first run of the current version
    
    [self checkFirstRun];
        
}

/* View Functions */

-(void) dealloc
{
    // Remove notification listeners
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_drone.mainController stopUpdateMCSystemState];
    [_drone disconnectToDrone];
    [[VideoPreviewer instance] setView:nil];
    [self stopBatteryUpdate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*User Input Screens*/

- (IBAction)setYawAngle:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Yaw Angle" //or strTitle
                                                    message:@"Choose your desired yaw angle" //or pass message parameter
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    
    if(droneType == 1) { // Inspire 1
        [alertView addButtonWithTitle:@"30° (49 photos)"];
        [alertView addButtonWithTitle:@"45° (33 photos)"];
        [alertView addButtonWithTitle:@"60° (25 photos)"];
    } else if (droneType == 2) { // Phantom 3
        [alertView addButtonWithTitle:@"30° (37 photos)"];
        [alertView addButtonWithTitle:@"45° (25 photos)"];
        [alertView addButtonWithTitle:@"60° (19 photos)"];
    }
    
    alertView.tag = yawAngleTag;
    
    [alertView show];
    
}

// TODO: improve this because it sees 1.0.4 the same as 1.0.5 since it's casting both to float as 1.0
-(void) checkFirstRun {
    // First run popup Terms and Conditions
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Check for existence of version on first run
    if (![userDefaults valueForKey:@"version"] ) {
        // First version so show the terms
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *terms = [storyboard instantiateViewControllerWithIdentifier:@"Terms"];
        terms.modalPresentationStyle = UIModalPresentationPageSheet;
        [self presentViewController:terms animated:YES completion:nil];
        
        // Let's listen for the dismissal of the view controller so we can launch the select aircraft modal
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(displayDroneSelection)
                                                 name:@"TermsDismissed"
                                                 object:nil];
        
        // Adding version number to NSUserDefaults for first version
        [userDefaults setFloat:[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] floatValue] forKey:@"version"];
    } else {
        if(droneType == 0)
            [self displayDroneSelection];
    }
}

// Ask the user if they are flying I1 or P3
-(void) displayDroneSelection {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *whichDrone = [storyboard instantiateViewControllerWithIdentifier:@"WhichDrone"];
    [self presentViewController:whichDrone animated:YES completion:nil];
    
    // Listen for which drone is selected
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setWhichDrone:)
                                             name:@"DroneSelected"
                                             object:nil];
}

// When a user selects a drone this is called and the drone is set
-(void)setWhichDrone:(NSNotification*)notification {
    NSDictionary* userInfo = notification.userInfo;
    
    if([userInfo[@"drone"] isEqual:@"i1"]) {
        self.photoCountLabel.text = @"Photo: 0/25"; // Default photo count at 60 degrees for I1
        droneType = 1;
    } else {
        self.photoCountLabel.text = @"Photo: 0/19"; // Default photo count at 60 degrees for P3
        droneType = 2;
    }
    
    [self initDrone];
    
    [[NSNotificationCenter defaultCenter] removeObserver:@"DroneSelected"];
}

- (IBAction)captureMethod:(id)sender {
    if(droneType == 1 && panoInProgress == NO) { // Inspire 1
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Inspire 1 Capture Method" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yaw Aircraft", @"Yaw Gimbal", nil];
        alert.tag = captureMethodTag;
        [alert show];
    } else { // P3 or even I1 if the I1 pano is in progress
        //[self startPano];
        [self startNewPano];
    }
}

-(CommandResponseStatus) setCameraWorkModeToCapture{

    __block CommandResponseStatus status=failure;
    
    [_camera setCameraWorkMode:CameraWorkModeCapture withResult:^(DJIError *error) {
        if (error.errorCode == ERR_Succeeded) {
            status=success;
        }
    }];
    
    if(status==failure){
    
        [Utils displayToast:self.view message:@"Error setting camera work mode to capture"];
    }
    
    return status;
}

-(void) startNewPano{
    
    if(panoInProgress == NO) {
        
        [Utils displayToast:self.view message:@"Starting Panorama"];
     
        panoInProgress = YES;
        
        // Change start icon to a stop icon
        [self.startButton setBackgroundImage:[UIImage imageNamed:@"Stop Icon"] forState:UIControlStateNormal];
        
        totalProgress = 0;
        
        self.progressView.progress = 0;
        
        totalPhotoCount = 1;
       
        if([self setCameraWorkModeToCapture]==success){
            [self doPano];
        }
        
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm"
                                                        message:@"Are you sure you want to stop this panorama?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = stopPanoTag;
        [alert show];
        
    }

}

-(void) doPano{
    
    NSArray *pitch=@[@0, @-30,@-60,@-90,@30];
    
    NSArray *gimYaw=@[@60,@120,@180,@240,@300];
    
    NSArray *aircraftYaw=@[@90,@90,@90,@90,@90];
    
    NSMutableArray *yaw;
    
    if(captureMethod==YawAircraft)
    {
        yaw=[[NSMutableArray alloc] initWithArray:aircraftYaw];
    }else if(captureMethod==YawGimbal)
    {
        yaw=[[NSMutableArray alloc] initWithArray:gimYaw];
    }
    
    droneCmdsQueue=dispatch_queue_create("com.YourAppName.DroneCmdsQue",DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        __block int nC=0;
        
        for (NSNumber *nPitch in pitch) {
        //resetGimbal
        dispatch_sync(droneCmdsQueue,^{gcdResetGimbalYaw(_gimbal);});
        
        dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
        
        //setPitch
        dispatch_sync(droneCmdsQueue,^{gcdSetPitch(_gimbal,[nPitch floatValue]);});
        
        dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
        //
            // I was not sure about how many snaps @ 90 degrees 
            // If it is one single shot then uncomment the line below and corresponding else statements
            
            //if([nPitch integerValue]!=-90){
                
                for(NSNumber *nYaw in yaw){
                
                
                    dispatch_sync(droneCmdsQueue,^{gcdTakeASnap(_camera);});
                    dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
                
                    dispatch_sync(droneCmdsQueue,^{gcdTakeASnap(_camera);});
                    dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
                
                    dispatch_sync(droneCmdsQueue,^{gcdTakeASnap(_camera);});
                    dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
                
                    dispatch_sync(droneCmdsQueue,^{gcdSetCameraYaw([nYaw floatValue],_drone,_gimbal,droneCmdsQueue,captureMethod,nC++);});
                
                    dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
                
                    //dispatch_sync(dispatch_get_main_queue(),^(void){[];});
               
                    if(!panoInProgress){
                        break;
                    }
                }
            
            //uncomment the following lines if it is a single snap @ -90
            /*}
             else{
                dispatch_sync(droneCmdsQueue,^{gcdTakeASnap(_camera);});
                dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
                
                dispatch_sync(droneCmdsQueue,^{gcdTakeASnap(_camera);});
                dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
                
                dispatch_sync(droneCmdsQueue,^{gcdTakeASnap(_camera);});
                dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});

            }*/
    
        }
    
        dispatch_sync(dispatch_get_main_queue(),^(void){[self finishPanoAndReset];});
            
    });
    
}


-(void) startPano {
    if(panoInProgress == NO) {
        
        //[self displayToast:@"Starting Panorama"];
        [Utils displayToast:self.view message:@"Starting Panorama"];
        panoInProgress = YES;
        
        // Change start icon to a stop icon
        [self.startButton setBackgroundImage:[UIImage imageNamed:@"Stop Icon"] forState:UIControlStateNormal];
        
        totalProgress = 0;
        self.progressView.progress = 0;
        totalPhotoCount = 1;
        
        // Now let's set the gimbal to the starting location yaw = 0 pitch = 30
        [self resetGimbalYaw:nil];
        
#if (TARGET_IPHONE_SIMULATOR)
        [self rotatePhantomAndTakePhotos];
#else
        // Sleep for 3 seconds without blocking UI so we can display notification and set camera mode
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            __weak typeof(self) weakSelf = self;
            [_camera setCameraWorkMode:CameraWorkModeCapture withResult:^(DJIError *error) {
                if (error.errorCode != ERR_Succeeded) {
                    [weakSelf displayToast: @"Error setting camera work mode to capture"];
                    [weakSelf finishPanoAndReset];
                } else {
                    if(captureMethod == 1) // Yaw aircraft
                        [weakSelf enterNavigationMode];
                    else if(captureMethod == 2) // Yaw gimbal
                        [weakSelf takeFirstRowPhotos];
                }
            }];
        });
#endif
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm"
                                                        message:@"Are you sure you want to stop this panorama?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = stopPanoTag;
        [alert show];
    }
}

// Confirm that the user wants to stop the pano
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag == stopPanoTag) {
        if(buttonIndex == 1) {
            panoInProgress = NO;
            //[self displayToast:@"Stopping panorama, please stand by..."];
            [Utils displayToast:self.view message:@"Stopping panorama, please stand by..."];
        }
    } else if(alertView.tag == captureMethodTag) {
        // Index 1 = yaw aircraft, index 2 = yaw gimbal
        if(buttonIndex == 1) {
            captureMethod = 1;
            //[self startPano];
            [self startNewPano];
        } else if(buttonIndex == 2) {
            captureMethod = 2;
            
            //[self startPano];
            [self startNewPano];
        }
    } else if(alertView.tag == yawAngleTag) {
        if(buttonIndex == 1) {
            yawAngle = 30;
            numColumns = 12;
            
            if(droneType == 1)
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/49"];
            else if(droneType == 2)
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/37"];
            
        } else if(buttonIndex == 2) {
            yawAngle = 45;
            numColumns = 8;
            
            if(droneType == 1)
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/33"];
            else if(droneType == 2)
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/25"];
            
        } else if(buttonIndex == 3) {
            yawAngle = 60;
            numColumns = 6;
            
            if(droneType == 1)
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/25"];
            else if(droneType == 2)
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/19"];
        }
        
        // Update the yaw button text
        [self.yawAngleButton setTitle:[NSString stringWithFormat: @"Angle: %i°", yawAngle] forState:UIControlStateNormal];
    }
}

/* End of User Screens */




/*Drone Functions */


-(void)initDrone {
    _drone = [[DJIDrone alloc] initWithType: DJIDrone_Inspire];
    _drone.delegate = self;
    
    _gimbal = (DJIInspireGimbal*)_drone.gimbal;
    _gimbal.delegate = self;
    
    _camera = (DJIInspireCamera*)_drone.camera;
    _camera.delegate = self;
    
    mInspireMainController = (DJIInspireMainController*)_drone.mainController;
    mInspireMainController.mcDelegate = self;
    
    //Start video data decode thread
    [[VideoPreviewer instance] start];
    
    // For joystick API
    self.navigation = _drone.mainController.navigationManager;
    self.navigation.delegate = self;
}

-(void) connectToDrone {
    [_drone connectToDrone];
}


-(void) droneOnConnectionStatusChanged:(DJIConnectionStatus)status
{
    if (status == ConnectionSucceeded) {
        self.connectionStatusLabel.text = @"Connected";
        [self startBatteryUpdate];
    }
    else if(status == ConnectionBroken)
    {
        self.connectionStatusLabel.text = @"Disconnected";
    }
    else if (status == ConnectionFailed)
    {
        self.connectionStatusLabel.text = @"Failed";
    }
}

-(void)resetGimbalYaw{
    
    [_gimbal resetGimbalWithResult: nil];
}

static void (^gcdDelay)(unsigned int)=^(unsigned int delay){

    sleep(delay);
  
};
static void (^gcdTakeASnap)(DJIInspireCamera*)=^(DJIInspireCamera *camera){
    
    [camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
    
        if (error.errorCode != ERR_Succeeded) {
            
            NSString* myerror = [NSString stringWithFormat: @"Take photo error code: %lu", (unsigned long)error.errorCode];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [Utils displayToastOnApp:myerror];
            });
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [Utils displayToastOnApp:@"Clicked!"];
            });
        }
    }];
};

static void(^gcdSetPitch)(DJIInspireGimbal*,float)=^(DJIInspireGimbal *gimbal,float pitch){
    
    DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
    
    DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
    
    pitchRotation.angle = pitch;
    
    pitchRotation.angleType = AbsoluteAngle;
    
    pitchRotation.direction = pitchDir;
    
    pitchRotation.enable = YES;
    
    [gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
        
        if(error.errorCode != ERR_Succeeded) {
            
            NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
            
            NSLog(@"%@",myerror);
            
            [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed];
            
            
        }else{
            
            [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationSuccess];
            
           // [Utils displayToast:[UIApplication sharedApplication].keyWindow.rootViewController.view message:@"Gimbal Rotation Success"];
            
        }
    }];

};
static void(^gcdResetGimbalYaw)(DJIInspireGimbal*)=^(DJIInspireGimbal *gimbal){
    
    [gimbal resetGimbalWithResult: nil];
};
                   
static void (^gcdSetCameraYaw)(float,DJIDrone*,DJIInspireGimbal*,dispatch_queue_t,CaptureMode,NSUInteger)=^(float degreeYaw,DJIDrone *drone,DJIInspireGimbal *gimbal,dispatch_queue_t queue,CaptureMode captureMethod,NSUInteger cmdSeqNo){
    
    NSLog(@"Camera set Yaw %lu",(unsigned long)cmdSeqNo);
    
    dispatch_sync(queue,^(void){
        
       
        
        if(captureMethod==Gimbal)
        {
            DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
            pitchRotation.enable = NO;
            
            
            yawRotation.angle = degreeYaw;
            
            yawRotation.angleType = AbsoluteAngle;
            
            yawRotation.direction = RotationForward;
            
            yawRotation.enable = YES;
            
            [gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
                
                if(error.errorCode != ERR_Succeeded) {
                    
                    NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
                    
                    NSLog(@"%@",myerror);
                    
                    [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed];
                    
                    
                }else{
                    NSLog(@"Gimbal command success");
                    [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationSuccess];
                    
                }
            }];
        }
        
        if(captureMethod==Aircraft)
        {//90 Relative Works so just keep sending 90
            
            DJIFlightControlData ctrlData;
            ctrlData.mPitch = 0;
            ctrlData.mRoll = 0;
            ctrlData.mThrottle = 0;
            ctrlData.mYaw = degreeYaw;
            
            [drone.mainController.navigationManager.flightControl sendFlightControlData:ctrlData withResult:^(DJIError *error) {
                NSLog(@"Callback -----------------------+++++++++++++++++------------------------ worked!");
            }];
            
            NSLog(@"Aircraft Command Sent");
        }
        
        

    });
};

-(CommandResponseStatus) setCameraPitch:(float)pitch {
    DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
    
    DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
    
    pitchRotation.angle = pitch;
    
    pitchRotation.angleType = AbsoluteAngle;
    
    pitchRotation.direction = pitchDir;
    
    pitchRotation.enable = YES;
    
    [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
        
        if(error.errorCode != ERR_Succeeded) {
            
            NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
            
            NSLog(@"%@",myerror);
            
            [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed];
            
            
        }else{
            
            [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationSuccess];
            
            [Utils displayToast:[UIApplication sharedApplication].keyWindow.rootViewController.view message:@"Gimbal Rotation Success"];
            
        }
    }];
    
    return success;
}

-(CommandResponseStatus) setCameraPosition:(float)pitch yaw:(float) yaw{
    
    if(captureMethod==Gimbal)
    {
        DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
        
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        
        pitchRotation.angle = pitch;
        
        pitchRotation.angleType = AbsoluteAngle;
        
        pitchRotation.direction = pitchDir;
        
        pitchRotation.enable = YES;
        
        
        yawRotation.angle = yaw;
        
        yawRotation.angleType = AbsoluteAngle;
        
        yawRotation.direction = RotationForward;
        
        yawRotation.enable = YES;
        
        [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
            if(error.errorCode != ERR_Succeeded) {
                
                NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
                
                NSLog(@"%@",myerror);
                
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed];
                
                
            }else{
                
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationSuccess];
                
                [Utils displayToast:[UIApplication sharedApplication].keyWindow.rootViewController.view message:@"Gimbal Rotation Success"];
                
            }
        }];
    }
    
    if(captureMethod==Aircraft)
    {
        DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
        
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        
        pitchRotation.angle = pitch;
        
        pitchRotation.angleType = AbsoluteAngle;
        
        pitchRotation.direction = pitchDir;
        
        pitchRotation.enable = YES;
        
        yawRotation.enable=NO;
        
        [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
            if(error.errorCode != ERR_Succeeded) {
                
                NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
                
                NSLog(@"%@",myerror);
                
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed];
                
                
            }else{
                
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationSuccess];
                
                [Utils displayToast:[UIApplication sharedApplication].keyWindow.rootViewController.view message:@"Gimbal Rotation Success"];
                
            }
        }];
        
        
        DJIFlightControlData ctrlData;
        ctrlData.mPitch = 0;
        ctrlData.mRoll = 0;
        ctrlData.mThrottle = 0;
        ctrlData.mYaw = yaw;
        
        [_drone.mainController.navigationManager.flightControl sendFlightControlData:ctrlData withResult:^(DJIError *error) {
            NSLog(@"Callback -----------------------+++++++++++++++++------------------------ worked!");
        }];

}
    
    
    return success;
}


-(CommandResponseStatus) setCameraYaw:(float) yaw captureMethod:(CaptureMode)captureMethod{
    
    if(captureMethod==Gimbal)
    {
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        pitchRotation.enable = NO;
        
        
        yawRotation.angle = yaw;
        
        yawRotation.angleType = AbsoluteAngle;
        
        yawRotation.direction = RotationForward;
        
        yawRotation.enable = YES;
        
        [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
            if(error.errorCode != ERR_Succeeded) {
                
                NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
                
                NSLog(@"%@",myerror);
                
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed];
                
                
            }else{
                 NSLog(@"Gimbal command success");
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterGimbalRotationSuccess];
                
            }
        }];
    }
    
    if(captureMethod==Aircraft)
    {//90 Relative Works so just keep sending 90
        
        DJIFlightControlData ctrlData;
        ctrlData.mPitch = 0;
        ctrlData.mRoll = 0;
        ctrlData.mThrottle = 0;
        ctrlData.mYaw = yaw;
        
        [_drone.mainController.navigationManager.flightControl sendFlightControlData:ctrlData withResult:^(DJIError *error) {
            NSLog(@"Callback -----------------------+++++++++++++++++------------------------ worked!");
        }];
        
        NSLog(@"Aircraft Command Sent");
    }
    
    
    return success;
}

-(void) takeASnap{
    //dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    
    //dispatch_after(delay, dispatch_get_main_queue(), ^(void){
     //   __weak typeof(self) weakSelf = self;

    [_camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
        
        if (error.errorCode != ERR_Succeeded) {
            
            NSString* myerror = [NSString stringWithFormat: @"Take photo error code: %lu", (unsigned long)error.errorCode];
            [Utils displayToastOnApp:myerror];
            
        }else{
            [Utils displayToastOnApp:@"Clicked!"];
        }
    }];
    //});
}


-(void)enterNavigationMode {
    [self.navigation enterNavigationModeWithResult:^(DJIError *error) {
        if(error.errorCode != ERR_Succeeded) {
            NSString* myerror = [NSString stringWithFormat: @"Error entering navigation mode. Please place your mode switch in the F position. Code: %lu", (unsigned long)error.errorCode];
            //[self displayToast: myerror];
            [Utils displayToast:self.view message:myerror];
            [self finishPanoAndReset];
        } else {
            if(droneType == 1) {
                [self rotateInspireAndTakePhotos];
            } else if(droneType == 2) {
                [self rotatePhantomAndTakePhotos];
            }
        }
    }];
}


-(void)rotateInspireAndTakePhotos {

    if(self.droneAltitude < 5.0f) {
        //[self displayToast: @"Please increase altitude to > 5m to begin your panorama"];
        [Utils displayToast:self.view message:@"Please increase altitude to > 5m to begin your panorama"];
        [self finishPanoAndReset];
        return;
    }
    
    NSTimer *timer =  [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(warmingUp) userInfo:nil repeats:YES];
    [timer fire];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        sleep(2);
        
        [timer invalidate];
        
        [self doInspireLoop];
        
    });
}

// There will be 26 photos
-(void)doInspireLoop {
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    // Last loop
    // 8th or 10th or 14th column based on yaw angle
    if(currentLoop == (numColumns+2)) {
        currentLoop = 0;
        columnLoopCount = 0;
        
        //[self displayToast: @"Panorama complete. Please place your mode switch in the P position to take control of your aircraft."];
        [Utils displayToast:self.view message:@"Panorama complete. Please place your mode switch in the P position to take control of your aircraft."];
        [self finishPanoAndReset];
        return;
        
    // 2nd to last loop where we take the nadir shot
    // 7th or 9th or 13th column based on yaw
    } else if(currentLoop == (numColumns+1)) {
        
        currentLoop = numColumns+2;
        [self rotateGimbal2: -90 withYaw:0];
        
    } else if(columnLoopCount <= 3) {
        
        int pitchAngle = 30;
        
        if(columnLoopCount == 1)
            pitchAngle = 0;
        else if(columnLoopCount == 2)
            pitchAngle = -30;
        else if(columnLoopCount == 3)
            pitchAngle = -60;
        
        [self rotateGimbal2: pitchAngle withYaw:0];
        
        columnLoopCount = columnLoopCount + 1;
        
    // Current column is done so let's yaw and move to the next
    } else if (columnLoopCount == 4) {
        columnLoopCount = 0;
        currentLoop = currentLoop + 1;
        
        // To be safe we are going to try and delay 3 seconds before we yaw the drone
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
        
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self yawDrone: 90];
        });
    }
}

-(void) rotatePhantomAndTakePhotos {
    
    if(self.droneAltitude < 5.0f) {
        //[self displayToast: @"Please increase altitude to > 5m to begin your panorama"];
        [Utils displayToast:self.view message:@"Please increase altitude to > 5m to begin your panorama"];
        [self finishPanoAndReset];
        return;
    }
    
    NSTimer *timer =  [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(warmingUp) userInfo:nil repeats:YES];
    [timer fire];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Reset gimbal to straight forward
        //[self rotateGimbal2:0 withYaw:0];
        
        sleep(2);
        
        [timer invalidate];
        
        [self doPhantomLoop];
        
    });
}

// Process will be pitch gimbal up
// Take photo
// Pitch gimbal
// Take photo

-(void)doPhantomLoop {
    
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    // Last loop
    if(currentLoop == 8) {
        currentLoop = 0;
        columnLoopCount = 0;
        
        //[self displayToast: @"Panorama complete. Please place your mode switch in the P position to take control of your aircraft."];
        [Utils displayToast:self.view message: @"Panorama complete. Please place your mode switch in the P position to take control of your aircraft."];
        [self finishPanoAndReset];
        return;
        
    // 2nd to last loop where we take the nadir shot
    } else if(currentLoop == 7) {
        
        currentLoop = 8;
        [self rotateGimbal2: -90 withYaw:0];
        
    } else if(columnLoopCount <= 2) {
        
        int pitchAngle = 0;
        
        if(columnLoopCount == 1)
            pitchAngle = -30;
        else if(columnLoopCount == 2)
            pitchAngle = -60;
        
        
        [self rotateGimbal2: pitchAngle withYaw:0];
        
        columnLoopCount = columnLoopCount + 1;
        
    // Current column is done so let's yaw and move to the next
    } else if (columnLoopCount == 3) {
        columnLoopCount = 0;
        currentLoop = currentLoop + 1;
        
        // To be safe we are going to try and delay 3 seconds before we yaw the drone
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
        
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self yawDrone: 90];
        });
    }

    /*
    sleep(1);

    [self takePhoto2];
    
    sleep(3);
    
    [self rotateGimbal2:-30 withYaw:0];
    
    sleep(1);
    
    [self takePhoto2];
    
    sleep(3);

    [self rotateGimbal2:-60 withYaw:0];
    
    sleep(1);
    
    [self takePhoto2];
    
    sleep(3);
    
    [self yawDrone: 90];*/
    
    
    /*if(yawLoopCount <= 5) {
        
        // Panorama is complete
        if(currentLoop == 4 && yawLoopCount == 2) {
            [self displayToast: @"Panorama complete. Please place your mode switch in the P position to take control of your aircraft."];
            [self finishPanoAndReset];
            return;
        }
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self takePhoto2];
            
            // Incrementing in here because the dispatch call is asynchronous
            yawLoopCount = yawLoopCount + 1;
        });
    } else { // Loop done increment and move to the next loop
        
        yawLoopCount = 0;
        currentLoop = currentLoop + 1;
        
        // Need to pitch gimbal here
        // TODO: implement gimbal pitch based on loop
        if(currentLoop == 2) {
            [self rotateGimbal2:-30 withYaw:0];
        } else if(currentLoop == 3) {
            [self rotateGimbal2:-60 withYaw:0];
        } else if(currentLoop == 4) {
            [self rotateGimbal2:-90 withYaw:0];
        }
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            // Done with loop so let's start the next
            [self doPhantomLoop];
        });
    }*/
}


-(void)yawDrone:(float)yaw {
    
    DJIFlightControlData ctrlData;
    ctrlData.mPitch = 0;
    ctrlData.mRoll = 0;
    ctrlData.mThrottle = 0;
    ctrlData.mYaw = yaw;
    
    // THIS CALLBACK DOES NOT WORK!!!!
    // Yaw drone and if successful proceed to take the photo
    [self.navigation.flightControl sendFlightControlData:ctrlData withResult:^(DJIError *error) {
        
        // TODO: There is no callback happening here so let's ignore this for now and revisit
        //[self displayToast:@"Yaw callback is called!!!!"];
        /*if(error.errorCode != ERR_Successed) {
            NSString* myerror = [NSString stringWithFormat: @"Yaw aircraft error code: %lu", (unsigned long)error.errorCode];
            [self displayToast: myerror];
        } else {
            [self displayToast:@"Yaw success now take photo"];
            // We set the delay to 3 seconds in this case because the gimbal will slowly follow the aircraft when yawing
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
            
            // Take the photo
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [self takePhoto2];
            });
        }
         */
    }];
    
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
    
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        if(droneType == 1) // Inspire 1
            [self doInspireLoop];
        else if(droneType == 2) // Phantom 3
            [self doPhantomLoop];
    });
    
}

- (void)warmingUp {
    DJIFlightControlData noActionData;
    noActionData.mPitch = 0;
    noActionData.mRoll = 0;
    noActionData.mThrottle = 0;
    noActionData.mYaw = 0;
    [_navigation.flightControl sendFlightControlData:noActionData withResult:nil];
}

-(void)takeFirstRowPhotos {
    
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    if(firstLoopCount <= (numColumns - 1)) {
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self rotateGimbal:0.0 withYaw: (firstLoopCount*yawAngle)];
            
            // Incrementing in here because the dispatch call is asynchronous
            firstLoopCount = firstLoopCount + 1;
        });

    } else {
        firstLoopCount = 0;
        
        [self resetGimbalYaw:nil];
        
        // Let's give 3 seconds for gimbal to reset before starting next row
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self takeSecondRowPhotos];
        });
    }
    
}

// Pitch gimbal down to -30 degrees and take 6 photos at intervals from above
-(void)takeSecondRowPhotos {
    
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    if(secondLoopCount <= (numColumns-1)) {
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self rotateGimbal:-30.0 withYaw: (secondLoopCount*yawAngle)];
            
            // Incrementing in here because the dispatch call is asynchronous
            secondLoopCount = secondLoopCount + 1;
        });
        
    } else {
        
        secondLoopCount = 0;
        
        [self resetGimbalYaw:nil];
        
        // Let's give 3 seconds for gimbal to reset before starting next row
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self takeThirdRowPhotos];
        });
        
    }
}

// Pitch gimbal down to -30 degrees and take 6 photos at intervals from above
-(void)takeThirdRowPhotos {
    
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    if(thirdLoopCount <= (numColumns-1)) {
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self rotateGimbal:-60.0 withYaw: (thirdLoopCount*yawAngle)];
            
            // Incrementing in here because the dispatch call is asynchronous
            thirdLoopCount = thirdLoopCount + 1;
        });
        
    } else {
        
        thirdLoopCount = 0;
        
        [self resetGimbalYaw:nil];
        
        // Let's give 3 seconds for gimbal to reset before starting next row
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self takeFourthRowPhotos];
        });
        
    }
}

// Changing this to only take 1 nadir
-(void)takeFourthRowPhotos {
    
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    // Changing this so it should only take 1 photo now
    if(fourthLoopCount < 1) {
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self rotateGimbal:-90.0 withYaw: (fourthLoopCount*180)];
            
            // Incrementing in here because the dispatch call is asynchronous
            fourthLoopCount = fourthLoopCount + 1;
        });
        
    } else { // This is the end of the pano with gimbal rotation
        
        fourthLoopCount = 0;
        
        // Reset the pano flag
        panoInProgress = NO;
        
        // Send the gimbal back to its starting position
        [self rotateGimbal:0 withYaw:0];
        
        // Change the button status back to start
        [self.startButton setBackgroundImage:[UIImage imageNamed:@"Start Icon"] forState:UIControlStateNormal];
        
        self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/20"];
        
        self.progressView.progress = 0;
        
        [Utils displayToast:self.view message:@"Panorama Complete!"];
        
    }
}

-(void)rotateGimbal:(float)pitch withYaw:(float)yaw  {

    DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
    DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
    pitchRotation.angle = pitch;
    pitchRotation.angleType = AbsoluteAngle;
    pitchRotation.direction = pitchDir;
    pitchRotation.enable = YES;
    
    yawRotation.angle = yaw;
    yawRotation.angleType = AbsoluteAngle;
    yawRotation.direction = RotationForward;
    yawRotation.enable = YES;
    
    __weak typeof(self) weakSelf = self;

    [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
        // Gimbal rotation failed so we'll try again
        if(error.errorCode != ERR_Succeeded) {
            
            NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
            
            //[weakSelf displayToast:myerror];
            
            [Utils displayToast:weakSelf.view message:myerror];
            
            // Delay two seconds and try to rotate the gimbal again
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
            
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [weakSelf rotateGimbal:pitch withYaw:yaw];
            });
        // If we finish the fourth loop or if a user cancels before the pano is done
        } else if(panoInProgress == NO) {
            [weakSelf finishPanoAndReset];
        // Gimbal successfull rotate so we'll delay 2s and then take the photo
        } else {
            
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
            
            // Take the photo
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [weakSelf takePhoto];
            });
        }
    }];
}
         
 -(void)rotateGimbal2:(float)pitch withYaw:(float)yaw  {
     DJIGimbalRotationDirection pitchDir = pitch > 0 ? RotationForward : RotationBackward;
     DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
     pitchRotation.angle = pitch;
     pitchRotation.angleType = AbsoluteAngle;
     pitchRotation.direction = pitchDir;
     pitchRotation.enable = YES;
     
     yawRotation.angle = yaw;
     yawRotation.angleType = AbsoluteAngle;
     yawRotation.direction = RotationForward;
     yawRotation.enable = YES;
     
     __weak typeof(self) weakSelf = self;
     
     [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
         if(error.errorCode != ERR_Succeeded) {
             NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
             //[weakSelf displayToast:myerror];
             
             [Utils displayToast:weakSelf.view message:myerror];
             
             // Delay two seconds and try to rotate the gimbal again
             dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
             
             dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                 [weakSelf rotateGimbal:pitch withYaw:yaw];
             });
         // Gimbal pitch success now take photo
         } else {
             dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
             
             dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                 [weakSelf takePhoto2];
             });
         }
     }];
 }

// Used when rotating gimbal - I1 only
- (void)takePhoto {
    [_camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
        // Failed to get the photo
        if (error.errorCode != ERR_Succeeded) {

            NSString* myerror = [NSString stringWithFormat: @"Take photo error code: %lu", (unsigned long)error.errorCode];
            //[self displayToast:myerror];
            
             [Utils displayToast:self.view message:myerror];
            
            // There was an error trying to take the photo so we'll retry after 2 s
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
            
            // Take the photo
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [self takePhoto];
            });
            
        // Success
        } else {
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
            // Take the photo
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                if(firstLoopCount != 0)
                    [self takeFirstRowPhotos];
                else if(secondLoopCount != 0)
                    [self takeSecondRowPhotos];
                else if(thirdLoopCount != 0)
                    [self takeThirdRowPhotos];
                else if(fourthLoopCount != 0)
                    [self takeFourthRowPhotos];
            });
            
            // Update the photo count
            if(yawAngle == 30) {
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: %d/49", totalPhotoCount];
                self.progressView.progress = totalPhotoCount/49.0;
            } else if(yawAngle == 45) {
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: %d/33", totalPhotoCount];
                self.progressView.progress = totalPhotoCount/33.0;
            } else if(yawAngle == 60) {
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: %d/25", totalPhotoCount];
                self.progressView.progress = totalPhotoCount/25.0;
            }
            
            totalPhotoCount = totalPhotoCount + 1;
            
        }
    }];
}


// Used when yawing the aircraft - both P3 and I1
- (void)takePhoto2 {
    [_camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
        // Failed to get the photo
        if (error.errorCode != ERR_Succeeded) {
            
            NSString* myerror = [NSString stringWithFormat: @"Take photo error code: %lu", (unsigned long)error.errorCode];
            //[self displayToast:myerror];
            
            [Utils displayToast:self.view message:myerror];
            
            // There was an error trying to take the photo so we'll retry after 2 s
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
            
            // Take the photo
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [self takePhoto2];
            });
            
            // Success
        } else {
            
            // Introducing additional delay (increased from 2 o 3s) given sometimes the aircraft doesn't yaw when we tell it
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
            
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                if(droneType == 1) {
                    self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: %d/26", totalPhotoCount];
                    self.progressView.progress = totalPhotoCount/26.0;
                    [self doInspireLoop];
                } else if(droneType == 2) {
                    [self doPhantomLoop];
                    self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: %d/20", totalPhotoCount];
                    self.progressView.progress = totalPhotoCount/20.0;
                }
                totalPhotoCount = totalPhotoCount + 1;
            });
        }
    }];
}

// Check to see if the user canceled the pano
-(BOOL) continueWithPano {
    
    // User canceled the pano - reset a bunch of vars
    if(panoInProgress == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Panorama Stopped" message:@"Your panorama has been stopped and gimbal reset. You may start a new panorama by clicking the Start button." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
            
            [self finishPanoAndReset];
        });
        
        return NO;
    // Continue with the pano
    } else {
        return YES;
    }
}

-(void) finishPanoAndReset {
    
    self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/20"];
    
    // Change the stop button back to a start button
    [self.startButton setBackgroundImage:[UIImage imageNamed:@"Start Icon"] forState:UIControlStateNormal];
    
    // Reset the yaw
    [self resetGimbalYaw:nil];
    
    // Reset the gimbal pitch
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        // TODO: had to put all this code here for the time being otherwise calling rotateGimbal would result in an infinite
        // loop when panoInProgress = NO
        DJIGimbalRotationDirection pitchDir = RotationBackward;
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        pitchRotation.angle = 0;
        pitchRotation.angleType = AbsoluteAngle;
        pitchRotation.direction = pitchDir;
        pitchRotation.enable = YES;
        
        yawRotation.angle = 0;
        yawRotation.angleType = AbsoluteAngle;
        yawRotation.direction = RotationForward;
        yawRotation.enable = YES;
        [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
        }];
    });
    
    // Reset loop vars
    firstLoopCount = secondLoopCount = thirdLoopCount = fourthLoopCount = 0;
    
    // Reset progress indicator
    self.progressView.progress = 0;
    totalPhotoCount = totalProgress = 0;
    
    panoInProgress = NO;
}

-(void) startBatteryUpdate
{
    if (_readBatteryInfoTimer == nil) {
        _readBatteryInfoTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(batteryTimer:) userInfo:nil repeats:YES];
    }
}

-(void) batteryTimer:(id)timer {
    // Update battery status
    [_drone.smartBattery updateBatteryInfo:^(DJIError *error) {
        if (error.errorCode == ERR_Succeeded) {
            _batteryRemainingLabel.text = [NSString stringWithFormat: @"Battery: %ld%%", (long)_drone.smartBattery.remainPowerPercent];
        }
    }];
}

-(void) stopBatteryUpdate
{
    if (_readBatteryInfoTimer) {
        [_readBatteryInfoTimer invalidate];
        _readBatteryInfoTimer = nil;
    }
}

// Reset the gimbal yaw
- (IBAction)resetGimbalYaw:(id)sender {
    [_gimbal resetGimbalWithResult: nil];
}

-(void) resetGimbalPitch {
    DJIGimbalRotation pitch = {YES, 180, RelativeAngle, RotationForward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationForward};
    DJIGimbalRotation yaw = {NO, 0, RelativeAngle, RotationForward};
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:nil];
}

// Hide the status bar
-(BOOL)prefersStatusBarHidden{
    return YES;
}

#pragma mark - DJIMainControllerDelegate
-(void) mainController:(DJIMainController*)mc didUpdateSystemState:(DJIMCSystemState*)state {
    DJIMCSystemState* inspireSystemState = (DJIMCSystemState*)state;
    {
        self.droneAltitude = inspireSystemState.altitude;
        self.altitudeLabel.text =[NSString stringWithFormat: @"Alt: %dm", (int)self.droneAltitude];
    }
}

#pragma mark - DJIGimbalDelegate
-(void) gimbalController:(DJIGimbal *)controller didUpdateGimbalState:(DJIGimbalState*)gimbalState {
    self.yawLabel.text = [NSString stringWithFormat:@"Yaw: %d", (int)gimbalState.attitude.yaw];
    self.pitchLabel.text = [NSString stringWithFormat:@"Pitch: %d", (int)gimbalState.attitude.pitch];
}

#pragma mark - DJICameraDelegate

-(void) camera:(DJICamera*)camera didReceivedVideoData:(uint8_t*)videoBuffer length:(int)length {
    uint8_t* pBuffer = (uint8_t*)malloc(length);
    memcpy(pBuffer, videoBuffer, length);
    [[VideoPreviewer instance].dataQueue push:pBuffer length:length];
}

-(void) camera:(DJICamera*)camera didUpdateSystemState:(DJICameraSystemState*)systemState
{
    if (!systemState.isTimeSynced) {
        [_camera syncTime:nil];
    }
    if (systemState.isUSBMode) {
        [_camera setCamerMode:CameraCameraMode withResultBlock:Nil];
    }
    // This may not be necessary
    // See here: http://forum.dji.com/thread-12861-1-1.html
    /*if (_drone.droneType == DJIDrone_Inspire) {
        if (systemState.workMode != CameraWorkModeCapture) {
            DJIInspireCamera* inspireCamera = (DJIInspireCamera*)_camera;
            [inspireCamera setCameraWorkMode:CameraWorkModeCapture withResult:nil];
        }
    }*/
}

/*
 [_camera getCameraISO:^(CameraISOType iso, DJIError *error) {
 if (error.errorCode == ERR_Successed) {
 int index = (int)iso;
 }
 else

 {
 
 }
 }];
 */

#pragma mark - DJINavigationDelegate Method
-(void) onNavigationMissionStatusChanged:(DJINavigationMissionStatus*)missionStatus {
    /*if (self.isMissionStarted && missionStatus.missionType == DJINavigationMissionNone) {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Ground Station" message:@"mission finished" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        self.isMissionStarted = NO;
    }*/
}
/*-(void) runModuleTest1{
 
 
 [[NSNotificationCenter defaultCenter] addObserver:self
 selector:@selector(notificationReceived)
 name:NotificationDroneConnected
 object:nil];
 
 
 [Utils sendNotificationWithNoteType:NotificationDroneConnected noteType:CmdCenterDroneConnected];
 }
 
 -(void) notificationReceived{
 
 [Utils displayToastOnApp:@"Received Notification"];
 }
 
 -(void) runDeviceTest{
 
 
 [[NSNotificationCenter defaultCenter] addObserver:self
 selector:@selector(onDroneConnected)
 name:NotificationDroneConnected
 object:nil];
 
 [[NSNotificationCenter defaultCenter] addObserver:self
 selector:@selector(processCmdCenterUpdates:)
 name:NotificationCmdCenter
 object:nil];
 
 
 
 //[DroneCommandCenter initialize:DJIDrone_Inspire];
 
 
 }
 
 -(void) processCmdCenterUpdates:(NSNotification *) notice{
 
 NSDictionary  *userInfo=notice.userInfo;
 
 NSLog(@"%@",notice.name);
 
 if(userInfo!=nil)
 {
 
 NSLog(@"%@", [userInfo objectForKey:@"NoteType"]);
 
 }
 }
 
 
 -(void) onDroneConnected{
 
 [Utils displayToastOnApp:@"Inspire 1 Drone Connected"];
 
 NSArray *pitch=@[@0, @-30,@-60,@-90,@30];
 NSArray *yaw=@[@60,@120,@180,@240,@300];
 
 for (NSNumber *nPitch in pitch) {
 
 [Utils displayToastOnApp:@"Resetting Gimble"];
 [DroneCommandCenter resetGimbalYaw];
 [DroneCommandCenter setCameraPitch:[nPitch floatValue]];
 [Utils displayToastOnApp:@"Gimble Reset Complete!"];
 
 sleep(1);
 
 [DroneCommandCenter takeASnap];
 
 sleep(5);
 
 if([nPitch integerValue]!=-90){
 for(NSNumber *nYaw in yaw){
 
 [DroneCommandCenter setCameraYaw:[nYaw floatValue]];
 
 [Utils displayToastOnApp:@"Gimble Rotate to 60 Degree Complete!"];
 
 sleep(1);
 
 [DroneCommandCenter takeASnap];
 
 sleep(5);
 }
 }
 }
 
 }*/

@end
