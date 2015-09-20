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
#import <DJISDK/DJISDK.h>
#import <GoogleMaps/GoogleMaps.h>

#define stopPanoTag 100
#define captureMethodTag 200

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
        self.photoCountLabel.text = @"Photo: 0/26";
        droneType = 1;
    } else {
        droneType = 2;
    }
    
    [self initDrone];
    
    [[NSNotificationCenter defaultCenter] removeObserver:@"DroneSelected"];
}

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


-(void) dealloc
{
    [_drone destroy];
    // Remove notification listeners
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

-(void) connectToDrone {
    [_drone connectToDrone];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_drone.mainController stopUpdateMCSystemState];
    [_drone disconnectToDrone];
    [_drone destroy];
    [[VideoPreviewer instance] setView:nil];
    [self stopBatteryUpdate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) droneOnConnectionStatusChanged:(DJIConnectionStatus)status
{
    if (status == ConnectionSuccessed) {
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

- (void)displayToast:(NSString *)message {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.color = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = message;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:5];
}


- (IBAction)captureMethod:(id)sender {
    if(droneType == 1 && panoInProgress == NO) { // Inspire 1
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Inspire 1 Capture Method" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yaw Aircraft", @"Yaw Gimbal", nil];
        alert.tag = captureMethodTag;
        [alert show];
    } else { // P3 or even I1 if the I1 pano is in progress
        [self startPano];
    }
}

-(void) startPano {
    if(panoInProgress == NO) {
        
        [self displayToast:@"Starting Panorama"];
        
        panoInProgress = YES;
        
        // Change start icon to a stop icon
        [self.startButton setBackgroundImage:[UIImage imageNamed:@"Stop Icon"] forState:UIControlStateNormal];
        
        totalProgress = 0;
        self.progressView.progress = 0;
        totalPhotoCount = 1;
        
        // Now let's set the gimbal to the starting location yaw = 0 pitch = 30
        [self resetGimbalYaw:nil];
        
        // Sleep for 3 seconds without blocking UI so we can display notification and set camera mode
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            __weak typeof(self) weakSelf = self;
            [_camera setCameraWorkMode:CameraWorkModeCapture withResult:^(DJIError *error) {
                if (error.errorCode != ERR_Successed) {
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
            [self displayToast:@"Stopping panorama, please stand by..."];
        }
    } else if(alertView.tag == captureMethodTag) {
        // TODO: figure out how to branch the two approaches below
        // Index 1 = yaw aircraft, index 2 = yaw gimbal
        if(buttonIndex == 1) {
            captureMethod = 1;
            [self startPano];
        } else if(buttonIndex == 2) {
            captureMethod = 2;
            [self startPano];
        }
    }
}

-(void)enterNavigationMode {
    [self.navigation enterNavigationModeWithResult:^(DJIError *error) {
        if(error.errorCode != ERR_Successed) {
            NSString* myerror = [NSString stringWithFormat: @"Error entering navigation mode. Please place your mode switch in the F position. Code: %lu", (unsigned long)error.errorCode];
            [self displayToast: myerror];
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
        [self displayToast: @"Please increase altitude to > 5m to begin your panorama"];
        [self finishPanoAndReset];
        return;
    }
    
    NSTimer *timer =  [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(warmingUp) userInfo:nil repeats:YES];
    [timer fire];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Reset gimbal to straight forward
        [self rotateGimbal2:30 withYaw:0];
        
        sleep(2);
        
        [timer invalidate];
        
        for(int i = 1;i <= 26; i++){
            
            // Check to see if the user canceled the pano
            if(![self continueWithPano]) break;
            
            // Need to fix this because of the necessary retry logic for when a photo is missed
            [self takePhoto2];
            
            sleep(3);
            
            // Yaw the aircraft - 90 represents 60 degrees
            [self yawDrone: 90];
            
            sleep(3);
            
            // End of first loop - pitch gimbal to 0
            if(i==6) {
                [self rotateGimbal2:0 withYaw:0];
                sleep(3);
                // End of second loop - pitch gimbal to -30
            } else if(i == 12) {
                [self rotateGimbal2:-30 withYaw:0];
                sleep(3);
                // End of third loop - pitch gimbal to - 60
            } else if(i == 18) {
                [self rotateGimbal2:-60 withYaw:0];
                sleep(3);
                // End of fourth loop
            } else if(i == 24) {
                [self rotateGimbal2:-90 withYaw:0];
                sleep(3);
            } else if(i == 26) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self displayToast: @"Panorama complete. Please place your mode switch in the P position to take control of your aircraft."];
                    [self finishPanoAndReset];
                });
            }
            
        } // End loop
        
    });
}

-(void) rotatePhantomAndTakePhotos {
    
    if(self.droneAltitude < 5.0f) {
        [self displayToast: @"Please increase altitude to > 5m to begin your panorama"];
        [self finishPanoAndReset];
        return;
    }
    
    NSTimer *timer =  [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(warmingUp) userInfo:nil repeats:YES];
    [timer fire];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Reset gimbal to straight forward
        [self rotateGimbal2:0 withYaw:0];
        
        sleep(2);
        
        [timer invalidate];
        
        for(int i = 1;i <= 20; i++){
            
            // Check to see if the user canceled the pano
            if(![self continueWithPano]) break;
            
            // Need to fix this because of the necessary retry logic for when a photo is missed
            [self takePhoto2];
            
            sleep(3);
            
            // Yaw the aircraft - 90 represents 60 degrees
            [self yawDrone: 90];
            
            sleep(3);
            
            if(i==6) {
                [self rotateGimbal2:-30 withYaw:0];
                sleep(3);
            } else if(i == 12) {
                [self rotateGimbal2:-60 withYaw:0];
                sleep(3);
            } else if(i == 18) {
                [self rotateGimbal2:-90 withYaw:0];
                sleep(3);
            } else if(i == 20) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self displayToast: @"Panorama complete. Please place your mode switch in the P position to take control of your aircraft."];
                    [self finishPanoAndReset];
                });
            }
            
        } // End loop
        
    });
}

-(void)yawDrone:(float)yaw {
    DJIFlightControlData ctrlData;
    ctrlData.mPitch = 0;
    ctrlData.mRoll = 0;
    ctrlData.mThrottle = 0;
    ctrlData.mYaw = yaw;
    [self.navigation.flightControl sendFlightControlData:ctrlData withResult:nil];
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
    
    if(firstLoopCount <=5 ) {
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self rotateGimbal:0.0 withYaw: (firstLoopCount*60.0)];
            
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
    
    if(secondLoopCount <=5 ) {
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self rotateGimbal:-30.0 withYaw: (secondLoopCount*60.0)];
            
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
    
    if(thirdLoopCount <=5 ) {
        
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
        
        // Take the photo
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [self rotateGimbal:-60.0 withYaw: (thirdLoopCount*60.0)];
            
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

// Pitch all the way down and take 2 photos - one at 0 and one at 180
-(void)takeFourthRowPhotos {
    
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    if(fourthLoopCount <= 1) {
        
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
        
        [self displayToast:@"Panorama Complete!"];
        
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
        if(error.errorCode != ERR_Successed) {
            NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
            [weakSelf displayToast:myerror];
            
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
         if(error.errorCode != ERR_Successed) {
             NSString* myerror = [NSString stringWithFormat: @"Rotate gimbal error code: %lu", (unsigned long)error.errorCode];
             [weakSelf displayToast:myerror];
             
             // Delay two seconds and try to rotate the gimbal again
             dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
             
             dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                 [weakSelf rotateGimbal:pitch withYaw:yaw];
             });
         }
     }];
 }

// Used when rotating gimbal
- (void)takePhoto {
    [_camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
        // Failed to get the photo
        if (error.errorCode != ERR_Successed) {

            NSString* myerror = [NSString stringWithFormat: @"Take photo error code: %lu", (unsigned long)error.errorCode];
            [self displayToast:myerror];
            
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
            self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: %d/20", totalPhotoCount];
            // Update the progress indicator
            self.progressView.progress = totalPhotoCount/20.0;
            totalPhotoCount = totalPhotoCount + 1;
            
        }
    }];
}


// Used when yawing the aircraft
- (void)takePhoto2 {
    [_camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
        // Failed to get the photo
        if (error.errorCode != ERR_Successed) {
            
            NSString* myerror = [NSString stringWithFormat: @"Take photo error code: %lu", (unsigned long)error.errorCode];
            [self displayToast:myerror];
            
            // There was an error trying to take the photo so we'll retry after 2 s
            dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
            
            // Take the photo
            dispatch_after(delay, dispatch_get_main_queue(), ^(void){
                [self takePhoto2];
            });
            
            // Success
        } else {
            
            // Update the photo count
            if(droneType == 1) {
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: %d/26", totalPhotoCount];
                self.progressView.progress = totalPhotoCount/26.0;
            } else if(droneType == 2) {
                self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: %d/20", totalPhotoCount];
                self.progressView.progress = totalPhotoCount/20.0;
            }
            
            totalPhotoCount = totalPhotoCount + 1;
            
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
        if (error.errorCode == ERR_Successed) {
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

@end
