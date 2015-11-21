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
    
    //#unused
    // Temp test for widths of status indicators
    /*self.photoCountLabel.text = @"Photo: 20/20";
     self.batteryRemainingLabel.text = @"Battery: 100%";
     self.altitudeLabel.text = @"Alt: 200m";
     self.yawLabel.text = @"Yaw: 180";
     self.pitchLabel.text = @"Pitch: -90";*/
    
    //#unused
    //firstLoopCount = secondLoopCount = thirdLoopCount = fourthLoopCount = 0;
    
    //currentLoop = 1;
    
    //yawLoopCount = 0;
    
    //columnLoopCount = 0;
    
    //#unused
    //numColumns = 6; // We take 6 columns or 6 rotations of photos by default
    
    
    
   
    [self.progressView setTransform:CGAffineTransformMakeScale(1.0, 100.0)];
    
   
    self.progressView.progress = 0;
    
    panoInProgress = NO;
   
    // Variables for yaw angle
    
    yawAngle = 60; // 60 is our default yaw angle
    
    
    // By default we'll use the yaw aircraft capture method
    
    captureMethod = 1;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cameraModeSet)
                                                 name:NotificationCameraModeSet
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processCmdCenterNotifications:)
                                                 name:NotificationCmdCenter
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(navigationModeSet)
                                                 name:NotificationNavigationModeSet
                                               object:nil];
    
    
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


// Prompt the user to choose the drone for flying I1 or P3
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
        
        [self startNewPano];
    }
}

-(void) setCameraWorkModeToCapture{

    //__block CommandResponseStatus status=failure;
    
    //dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    //runOnMainQueueWithoutDeadlocking(^{
    
    __weak typeof(self) weakSelf = self;

        [_camera setCameraWorkMode:CameraWorkModeCapture withResult:^(DJIError *error) {
                    if (error.errorCode == ERR_Succeeded) {
            
                //status=success;
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:NotificationCameraModeSet
                 object:nil];


            }else{
                
                [Utils displayToast:weakSelf.view message:@"Error setting camera work mode to capture"];
                //if(status==failure){
                //[Utils displayToast:self.view message:@"Error setting camera work mode to capture"];
                //}

            }
    
        }];
    
      // dispatch_semaphore_signal(sem);
    //});
    //dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
}

-(void) setNavigationMode{
 
    [self.navigation enterNavigationModeWithResult:^(DJIError *error) {
    
        if(error.errorCode != ERR_Succeeded) {
        
            NSString* myerror = [NSString stringWithFormat: @"Error entering navigation mode. Please place your mode switch in the F position. Code: %lu", (unsigned long)error.errorCode];
            
            [Utils displayToast:self.view message:myerror];
        
        }else{
        
            [[NSNotificationCenter defaultCenter]
             postNotificationName:NotificationNavigationModeSet
             object:nil];
        }
    }];
}

-(void) navigationModeSet{
    
    [self setCameraWorkModeToCapture];

}


-(void) cameraModeSet{
    
    timer=  [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(warmingupAircraft) userInfo:nil repeats:YES];
    
    [timer fire];

    warmUpCounter=0;
}


-(void) warmingupAircraft{
    
    DJIFlightControlData noActionData;
    noActionData.mPitch = 0;
    noActionData.mRoll = 0;
    noActionData.mThrottle = 0;
    noActionData.mYaw = 0;
    
    [_navigation.flightControl sendFlightControlData:noActionData withResult:nil];
    
    if(warmUpCounter>30)
    {
        [timer invalidate];
   
        warmUpCounter=0;
        
        //[self doPano];
        [self doPanoYawThenPitch];
    
    }else{
    
        warmUpCounter++;
    }
    
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
       
        
        if((droneType==1 && YawAircraft) || (droneType==2))
        {
            if(self.droneAltitude < 5.0f) {
           
                [Utils displayToast:self.view message:@"Please increase altitude to > 5m to begin your panorama"];
                
                [self finishPanoAndReset];
                
                return;
            }

            [self setNavigationMode];
            
        }else{
            
            [self setCameraWorkModeToCapture];
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

-(void) doPanoYawThenPitch{
    
    NSArray *pitchGimbalYaw=@[@30,@0,@-30,@-60];
    
    NSArray *pitchAircraftYaw=@[@30,@0,@-30,@-60];
    
    NSArray *gimYaw30=@[@0,@30,@60,@90,@120,@150,@180,@210,@240,@270,@300,@330];
    
    NSArray *aircraftYaw30=@[@0,@45,@45,@45,@45,@45,@45,@45,@45,@45,@45,@45];
    
    NSArray *gimYaw45=@[@0,@45,@90,@135,@180,@225,@270,@315];
    
    NSArray *aircraftYaw45=@[@0,@67.5,@67.5,@67.5,@67.5,@67.5,@67.5,@67.5];
    
    NSArray *gimYaw60=@[@0,@60,@120,@180,@240,@300];
    
    NSArray *aircraftYaw60=@[@0,@90,@90,@90,@90,@90];
    
    
    NSMutableArray *yaw;
    NSMutableArray *pitch;
    
    if(captureMethod==YawAircraft)
    {
        pitch=[[NSMutableArray alloc] initWithArray:pitchAircraftYaw];
        
        if(droneType==2)
        {
            [pitch removeObjectAtIndex:0];
        }
        
    }else if(captureMethod==YawGimbal){
        pitch=[[NSMutableArray alloc] initWithArray:pitchGimbalYaw];
    }
    
    
    
    switch(yawAngle){
        
        case 30:{
            if(captureMethod==YawAircraft)
            {
                yaw=[[NSMutableArray alloc] initWithArray:aircraftYaw30];
                
            }else if(captureMethod==YawGimbal)
            {
                yaw=[[NSMutableArray alloc] initWithArray:gimYaw30];
            }
            break;
        }
       
        case 45:{
            if(captureMethod==YawAircraft)
            {
                yaw=[[NSMutableArray alloc] initWithArray:aircraftYaw45];
                
            }else if(captureMethod==YawGimbal)
            {
                yaw=[[NSMutableArray alloc] initWithArray:gimYaw45];
            }
            break;
        }
      
        case 60:
        default:{
            if(captureMethod==YawAircraft)
            {
                yaw=[[NSMutableArray alloc] initWithArray:aircraftYaw60];
                
            }else if(captureMethod==YawGimbal)
            {
                yaw=[[NSMutableArray alloc] initWithArray:gimYaw60];
            }
            break;
        }
    }
    
    
    droneCmdsQueue=dispatch_queue_create("com.dronepan.queue",DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        dispatch_sync(droneCmdsQueue,^{gcdResetGimbalYaw(_gimbal);});
        
        dispatch_sync(droneCmdsQueue,^{gcdDelay(5);});
        
        
        for (NSNumber *nYaw in yaw) {
        
            
            __block float nDegreeYaw=[nYaw floatValue];

            if(captureMethod==YawAircraft)
            {
                dispatch_sync(droneCmdsQueue,^{gcdYawDrone(nDegreeYaw,self.navigation);});
                
                dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
            }
            
            for (NSNumber *nPitch in pitch){
                
                
                __block float nDegreePitch=[nPitch floatValue];
                     
                nDegreePitch=[nPitch floatValue];
                
                if(captureMethod==YawGimbal){

                    dispatch_sync(droneCmdsQueue,^{gcdYawGimbal(nDegreePitch,nDegreeYaw,_gimbal);});
                
                }else{

                dispatch_sync(droneCmdsQueue,^{gcdSetPitch(_gimbal,nDegreePitch);});
                
                }
                
                dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
                
                dispatch_sync(droneCmdsQueue,^{gcdTakeASnap(_camera);});
  
                dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
                
                if(!panoInProgress){
                
                    break;
                }
            
            }
                 
            if(captureMethod==YawAircraft)
            {
                dispatch_sync(droneCmdsQueue,^{gcdYawDrone(nDegreeYaw,self.navigation);});
                  
                dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
            }
            
         
            if(!panoInProgress){
                break;
            }
           
        }
    
        // Single nadir shot
        if(panoInProgress)
        {
            if(captureMethod==YawGimbal){
            
                dispatch_sync(droneCmdsQueue,^{gcdYawGimbal(-90,0,_gimbal);});
            
            }else{
            
                dispatch_sync(droneCmdsQueue,^{gcdSetPitch(_gimbal,-90);});
            
            }
        
            dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
        
            dispatch_sync(droneCmdsQueue,^{gcdTakeASnap(_camera);});
        
            dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
        }
        
        dispatch_sync(dispatch_get_main_queue(),^(void){[self finishPanoAndReset];});
            
    });
    
}

// Confirm that the user wants to stop the pano
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
 
    if(alertView.tag == stopPanoTag) {
    
        if(buttonIndex == 1) {
        
            panoInProgress = NO;
            
            [Utils displayToast:self.view message:@"Stopping panorama, please stand by..."];
        }
    } else if(alertView.tag == captureMethodTag) {
     
        // Index 1 = yaw aircraft, index 2 = yaw gimbal
        
        if(buttonIndex == 1) {
        
            captureMethod = 1;
            //#unused
            //[self startPano];
            
            [self startNewPano];
        
        } else if(buttonIndex == 2) {
        
            captureMethod = 2;
            
            //#unused
            //[self startPano];
            
            [self startNewPano];
        }
    } else if(alertView.tag == yawAngleTag) {
        
        if(buttonIndex == 1) {
        
            yawAngle = 30;
            
            //#unused
            numColumns = 12;
            
            if(droneType == 1)
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/49"];
            else if(droneType == 2)
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/37"];
            
        } else if(buttonIndex == 2) {
            
            yawAngle = 45;
            
            //#unused
            numColumns = 8;
            
            if(droneType == 1)
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/33"];
            else if(droneType == 2)
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/25"];
            
        } else if(buttonIndex == 3) {
            
            yawAngle = 60;
            
            //#unused
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
static void (^gcdDelayCM)(CaptureMode)=^(CaptureMode captureMode){

    unsigned int delay=(captureMode==YawAircraft)?5:2;
    sleep(delay);
  
};

static void (^gcdTakeASnap)(DJIInspireCamera*)=^(DJIInspireCamera *camera){
    
    __block BOOL snapOperationComplete=false;
    
    [camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
    
        if (error.errorCode != ERR_Succeeded) {
            
            __block NSString* myerror = [NSString stringWithFormat: @"Take photo error code: %lu", (unsigned long)error.errorCode];
            
            dispatch_async(dispatch_get_main_queue(), ^(void){
                
                snapOperationComplete=true;
                
                //[Utils displayToastOnApp:myerror];
                
                NSDictionary *dict=@{@"errorInfo":myerror};
                
                [Utils sendNotificationWithAdditionalInfo:NotificationCmdCenter noteType:CmdCenterSnapFailed additionalInfo:dict];
            });
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^(void){
           
                snapOperationComplete=true;
                
                [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterSnapTaken];
                //[Utils displayToastOnApp:@"Clicked!"];
            });
        }
    }];
    
    //NSDate *delaySinceThen=[NSDate dateWithTimeIntervalSinceNow:2.0];
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.5];
    
    while(!snapOperationComplete){
        
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:loopUntil];
        
        loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.5];
    }
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
            
        }
    }];

};

static void(^gcdResetGimbalYaw)(DJIInspireGimbal*)=^(DJIInspireGimbal *gimbal){
    
    [gimbal resetGimbalWithResult: nil];
};


static void (^gcdYawGimbal)(float,float,DJIInspireGimbal*)=^(float degreePitch,float degreeYaw,DJIInspireGimbal *gimbal){
    
        DJIGimbalRotationDirection pitchDir = degreePitch > 0 ? RotationForward : RotationBackward;
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        pitchRotation.angle = degreePitch;
        pitchRotation.angleType = AbsoluteAngle;
        pitchRotation.direction = pitchDir;
        pitchRotation.enable = YES;
        
        yawRotation.angle = degreeYaw;
        yawRotation.angleType = AbsoluteAngle;
        yawRotation.direction = RotationForward;
        yawRotation.enable = YES;
        
        
        [gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
            if(error.errorCode != ERR_Succeeded) {
                
                NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
                
                NSLog(@"%@",myerror);
                
                NSDictionary *dict=@{@"errorInfo":myerror};
                
                [Utils sendNotificationWithAdditionalInfo:NotificationCmdCenter noteType:CmdCenterGimbalPitchYawRotationFailed additionalInfo:dict];
                
                
            }else{
                NSDictionary *dict=@{@"Pitch":@(degreePitch),@"Yaw":@(degreeYaw)};
                [Utils sendNotificationWithAdditionalInfo:NotificationCmdCenter noteType:CmdCenterGimbalPitchYawRotationSuccess additionalInfo:dict];
            }
        }];
};

static void (^gcdYawDrone)(float,NSObject<DJINavigation> *)=^(float degreeYaw,NSObject<DJINavigation> *navigation){
    
        DJIFlightControlData ctrlData;
        ctrlData.mPitch = 0;
        ctrlData.mRoll = 0;
        ctrlData.mThrottle = 0;
        ctrlData.mYaw = degreeYaw;
        
        [[navigation flightControl] sendFlightControlData:ctrlData withResult:^(DJIError *error)
         {
             [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterAircraftYawRotationSuccess];
         }];
    
};

static void (^gcdSetCameraPitchYaw)(float,float,DJIInspireGimbal*,NSObject<DJINavigation> *,CaptureMode)=^(float degreePitch,float degreeYaw,DJIInspireGimbal *gimbal,NSObject<DJINavigation> *navigation,CaptureMode captureMethod){
    
    
    if(captureMethod==YawGimbal)
    {
        DJIGimbalRotationDirection pitchDir = degreePitch > 0 ? RotationForward : RotationBackward;
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        pitchRotation.angle = degreePitch;
        pitchRotation.angleType = AbsoluteAngle;
        pitchRotation.direction = pitchDir;
        pitchRotation.enable = YES;

        yawRotation.angle = degreeYaw;
        yawRotation.angleType = AbsoluteAngle;
        yawRotation.direction = RotationForward;
        yawRotation.enable = YES;


        [gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
        
        if(error.errorCode != ERR_Succeeded) {
            
            NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
            
            NSLog(@"%@",myerror);
            
            NSDictionary *dict=@{@"errorInfo":myerror};
            
            [Utils sendNotificationWithAdditionalInfo:NotificationCmdCenter noteType:CmdCenterGimbalPitchYawRotationFailed additionalInfo:dict];
            
            
        }else{
            NSDictionary *dict=@{@"Pitch":@(degreePitch),@"Yaw":@(degreeYaw)};
            [Utils sendNotificationWithAdditionalInfo:NotificationCmdCenter noteType:CmdCenterGimbalPitchYawRotationSuccess additionalInfo:dict];
        }
    }];
    }
    
    if(captureMethod==YawAircraft){
        
        DJIGimbalRotationDirection pitchDir = degreePitch > 0 ? RotationForward : RotationBackward;
        DJIGimbalRotation pitchRotation, yawRotation, rollRotation = {0};
        pitchRotation.angle = degreePitch;
        pitchRotation.angleType = AbsoluteAngle;
        pitchRotation.direction = pitchDir;
        pitchRotation.enable = YES;
        
        
        [gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
            
            if(error.errorCode != ERR_Succeeded) {
                
                NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
                
                NSLog(@"%@",myerror);
                
                NSDictionary *dict=@{@"errorInfo":myerror};
                
                [Utils sendNotificationWithAdditionalInfo:NotificationCmdCenter noteType:CmdCenterGimbalRotationFailed additionalInfo:dict];
                
                
            }else{
                NSDictionary *dict=@{@"Pitch":@(degreePitch)};
                [Utils sendNotificationWithAdditionalInfo:NotificationCmdCenter noteType:CmdCenterGimbalPitchRotationSuccess additionalInfo:dict];
                
            }
        }];

    }

    if(captureMethod==YawAircraft)

    {//90 Relative Works so just keep sending 90
    
    DJIFlightControlData ctrlData;
    ctrlData.mPitch = 0;
    ctrlData.mRoll = 0;
    ctrlData.mThrottle = 0;
    ctrlData.mYaw = degreeYaw;
   
    [[navigation flightControl] sendFlightControlData:ctrlData withResult:^(DJIError *error)
    {
        [Utils sendNotificationWithNoteType:NotificationCmdCenter noteType:CmdCenterAircraftYawRotationSuccess];
    }];
    
    
    }

};

-(void) processCmdCenterNotifications:(NSNotification*)notification{
    
    
    NSDictionary* userInfo=notification.userInfo;
    NSInteger noteType=[[userInfo objectForKey:@"NoteType"] integerValue];

    //dispatch_async(dispatch_get_main_queue(), ^(void){
        
    switch(noteType){
  
        case CmdCenterGimbalRotationFailed:
        case CmdCenterGimbalPitchRotationFailed:
        case CmdCenterSnapFailed:
        case CmdCenterGimbalPitchYawRotationFailed:
        {
            [Utils displayToastOnApp:(NSString *)[userInfo objectForKey:@"errorInfo"]];
            break;
        }
        case CmdCenterGimbalPitchYawRotationSuccess:
        {
            NSMutableString *mesg=[NSMutableString stringWithFormat:@"Pitch : %@ and Yaw : %@",[userInfo  objectForKey:@"Pitch"],[userInfo objectForKey:@"Yaw"]];
            [Utils displayToastOnApp:mesg];
            break;
        }
        case CmdCenterGimbalPitchRotationSuccess:
        {
            [Utils displayToastOnApp:(NSString *)[NSString stringWithFormat:@"Pitch : %@",[userInfo objectForKey:@"Pitch"]]];
            break;
        }
        case CmdCenterGimbalRotationSuccess:
        {
            break;
        }
        case CmdCenterAircraftYawRotationSuccess:
        {
            [Utils displayToastOnApp:@"Aircraft Yaw Rotation function called"];
            
            break;
        }
        case CmdCenterSnapTaken:
        {
            [Utils displayToastOnApp:@"Clicked!"];
            
            //# photocount can be updated here
            
            dispatch_async(dispatch_get_main_queue(),^(void){
                
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
                
                totalPhotoCount++;
                
            });
            
            break;
        }
        default:{break;}
        
    }

   // });

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
        
        //#vmcomments Now we can use our static gcd functions
        
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
    
    // Reset loop vars #unused
    //firstLoopCount = secondLoopCount = thirdLoopCount = fourthLoopCount = 0;
    
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

void runOnMainQueueWithoutDeadlocking(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

@end
