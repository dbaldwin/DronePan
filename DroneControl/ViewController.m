//
//  ViewController.m
//  DroneControl
//
//  Created by Dennis Baldwin on 7/9/15.
//  Copyright (c) 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import "ViewController.h"
#import "VideoPreviewer.h"
#import <DJISDK/DJISDK.h>
#import <GoogleMaps/GoogleMaps.h>

@interface ViewController () {
    BOOL firstLocationUpdate_;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _drone = [[DJIDrone alloc] initWithType: DJIDrone_Inspire];
    _drone.delegate = self;
    
    _gimbal = (DJIInspireGimbal*)_drone.gimbal;
    _gimbal.delegate = self;
    
    _camera = (DJIInspireCamera*)_drone.camera;
    _camera.delegate = self;
    
    // Trying to get this to work to get altitude
    mInspireMainController = (DJIInspireMainController*)_drone.mainController;
    mInspireMainController.mcDelegate = self;
    
    
    //Start video data decode thread
    [[VideoPreviewer instance] start];
    
    self.progressView.progress = 0;
    panoInProgress = NO;
    firstLoopCount = secondLoopCount = thirdLoopCount = 0;
    
    yawAngles = [[NSArray alloc] initWithObjects:
                    [NSNumber numberWithFloat:0.0f],
                    [NSNumber numberWithFloat:60.0f],
                    [NSNumber numberWithFloat:120.0f],
                    [NSNumber numberWithFloat:180.0f],
                    [NSNumber numberWithFloat:240.0f],
                    [NSNumber numberWithFloat:300.0f],
                    nil];
}


-(void) dealloc
{
    [_drone destroy];
}

-(void) connectToDrone {
    [_drone connectToDrone];
}

- (IBAction)takePhoto:(id)sender {
    [_camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
        if (error.errorCode != ERR_Successed) {
            NSString* myerror = [NSString stringWithFormat: @"Code: %lu", (unsigned long)error.errorCode];
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:myerror delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        }
    }];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_drone connectToDrone];
    [[VideoPreviewer instance] setView:self.videoPreviewView];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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

// Confirm that the user wants to stop the pano
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case 1:
            panoInProgress = NO;
            break;
    }
}

- (IBAction)startPano:(id)sender {
    if(panoInProgress == NO) {
        
        panoInProgress = YES;
        
        [self.startButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self.startButton setBackgroundColor:[UIColor redColor]];
        
        totalProgress = 0;
        self.progressView.progress = 0;
        totalPhotoCount = 0;
        
        // Now let's set the gimbal to the starting location yaw = 0 pitch = 30
        [self resetGimbalYaw:nil];
        
        sleep(3);
        
        // Set the camera work mode
        __weak typeof(self) weakSelf = self;
        
        [_camera setCameraWorkMode:CameraWorkModeCapture withResult:^(DJIError *error) {
            if (error.errorCode != ERR_Successed) {
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error setting camera work mode to capture" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            } else {
                [weakSelf takeFirstRowPhotos];
            }
        }];
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm"
                                                        message:@"Are you sure you want to stop this panorama?"
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        [alert show];
    }
}


// Pitch straight ahead and take 6 photos
// Yaw take photo at
// 0 degrees
// 60 degrees
// 120 degrees
// 180 degrees
// 240 degrees
// 300 degrees
-(void)takeFirstRowPhotos {
    
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    if(firstLoopCount <=5 ) {
        // Rotate the gimbal to the proper location
        [self rotateGimbal:0.0 withYaw:[[yawAngles objectAtIndex: firstLoopCount] floatValue]];
        
        //NSLog(@"Loop %d, rotating gimbal to pitch: %f, yaw: %f", firstLoopCount, 0.0, [[yawAngles objectAtIndex: firstLoopCount] floatValue]);
        
        sleep(2);
        
        // Take the photo
        [self takePhoto:nil];
        
        sleep(2);
        
        firstLoopCount = firstLoopCount + 1;
        
        [self performSelectorInBackground:@selector(takeFirstRowPhotos) withObject:nil];
    } else {
        firstLoopCount = 0;
        
        [self resetGimbalYaw:nil];
        
        sleep(3);
        
        [self takeSecondRowPhotos];
        
    }
    
}

// Pitch gimbal down to -30 degrees and take 6 photos at intervals from above
-(void)takeSecondRowPhotos {
    
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    if(secondLoopCount <=5 ) {
        // Rotate the gimbal to the proper location
        [self rotateGimbal:-30.0 withYaw:[[yawAngles objectAtIndex: secondLoopCount] floatValue]];
        
        //NSLog(@"Loop %d, rotating gimbal to pitch: %f, yaw: %f", secondLoopCount, 0.0, [[yawAngles objectAtIndex: secondLoopCount] floatValue]);
        
        sleep(2);
        
        // Take the photo
        [self takePhoto:nil];
        
        sleep(2);
        
        secondLoopCount = secondLoopCount + 1;
        
        [self performSelectorInBackground:@selector(takeSecondRowPhotos) withObject:nil];
    } else {
        secondLoopCount = 0;
        
        [self resetGimbalYaw:nil];
        
        sleep(3);
        
        [self takeThirdRowPhotos];
        
    }
}

// Pitch gimbal down to -30 degrees and take 6 photos at intervals from above
-(void)takeThirdRowPhotos {
    
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    if(thirdLoopCount <=5 ) {
        // Rotate the gimbal to the proper location
        [self rotateGimbal:-60.0 withYaw:[[yawAngles objectAtIndex: thirdLoopCount] floatValue]];
        
        //NSLog(@"Loop %d, rotating gimbal to pitch: %f, yaw: %f", secondLoopCount, 0.0, [[yawAngles objectAtIndex: secondLoopCount] floatValue]);
        
        sleep(2);
        
        // Take the photo
        [self takePhoto:nil];
        
        sleep(2);
        
        thirdLoopCount = thirdLoopCount + 1;
        
        [self performSelectorInBackground:@selector(takeThirdRowPhotos) withObject:nil];
    } else {
        thirdLoopCount = 0;
        
        [self resetGimbalYaw:nil];
        
        sleep(3);
        
        [self takeFourthRowPhotos];
        
    }
}

// Pitch all the way down and take 2 photos - one at 0 and one at 180
-(void)takeFourthRowPhotos {
    
    // Check to see if user canceled pano
    if(![self continueWithPano]) return;
    
    // Check to see if user canceled pano
    [self continueWithPano];
    
    // First photo forward and down
    [self rotateGimbal:-90.0 withYaw:0.0];
    
    sleep(2);
    
    // Take the photo
    [self takePhoto:nil];
    
    sleep(2);
    
    // Second photo backward and down
    [self rotateGimbal:-90.0 withYaw:180.0];
    
    sleep(2);
    
    // Take the photo
    [self takePhoto:nil];
    
    sleep(2);
    
    // Send the gimbal back to its starting position
    [self rotateGimbal:0 withYaw:0];
    
    // Reset the pano flag
    panoInProgress = NO;
    
    // Change the button status back to start
    [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
    [self.startButton setBackgroundColor:[UIColor colorWithRed:13/255.0f green:112/255.0f blue:49/255.0f alpha:1.0f]];
    
    self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 20/20"];
    
    self.progressView.progress = 1.0;
    loopCount = 1;
    photoCount = 0;
    
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Panorama Complete!" message:@"Your 20 photos are now ready to be stitched into a panorama. You may click the Start button again to capture another panorama." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    
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
    
    [_gimbal setGimbalPitch:pitchRotation Roll:rollRotation Yaw:yawRotation withResult:^(DJIError *error) {
        //ShowResult(@"Set Gimbal Angle:%@", error.errorDescription);
    }];
}

// Check to see if the user canceled the pano
-(BOOL) continueWithPano {
    // User canceled the pano - reset a bunch of vars
    if(panoInProgress == NO) {
        self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/20"];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Panorama Stopped" message:@"Your panorama has been stopped and gimbal reset. You may start a new panorama by clicking the Start button." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        // Change the stop button back to a start button
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
        [self.startButton setBackgroundColor:[UIColor colorWithRed:13/255.0f green:112/255.0f blue:49/255.0f alpha:1.0f]];
        
        // Reset the yaw
        [self resetGimbalYaw:nil];
        
        sleep(2);
        
        // Reset the pitch
        [self rotateGimbal:0.0 withYaw:0.0];
        
        // Rest loop vars
        firstLoopCount = secondLoopCount = thirdLoopCount = 0;
        
        // Reset progress indicator
        self.progressView.progress = 0;
        totalProgress = 0;
        
        return NO;
    // Continue with the pano
    } else {
        // Update the counts and progress
        self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: %d/20", (int)totalProgress];
        self.progressView.progress = totalProgress/20.0;
        totalProgress = totalProgress + 1.0;
        
        
        return YES;
    }
}

/*
 We'll take a photo facing forward and then 12 photos at 30 degree increments after that
 */
/*
- (void)rotateGimbalAndTakePhoto {
    
    // The pano has been stopped so display message, reset gimbal and vars, then return
    if(panoInProgress == NO) {
        self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 0/48"];
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Panorama Stopped" message:@"Your panorama has been stopped and gimbal yaw reset. Please adjust your pitch with your left scroll wheel and click start to begin a new panorama." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        // Change the stop button back to a start button
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
        [self.startButton setBackgroundColor:[UIColor colorWithRed:13/255.0f green:112/255.0f blue:49/255.0f alpha:1.0f]];
        
        self.progressView.progress = 0;
        
        [self resetGimbalYaw:nil];
        
        return;
    }
    
    // Take the photo
    [self takePhoto:nil];
    
    sleep(2);
    
    photoCount = photoCount + 1;
    totalPhotoCount = totalPhotoCount + 1;
    totalProgress = totalProgress + 1.0;
    self.progressView.progress = totalProgress/50.0;
    
    self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: %d/48", totalPhotoCount];
    
    DJIGimbalRotation pitch = {YES, 0, RelativeAngle, RotationForward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationForward};
    // 30 degree rotation - units are 2X the angle
    DJIGimbalRotation yaw = {YES, 60, RelativeAngle, RotationForward};
    
    __weak typeof(self) weakSelf = self;
    
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:^(DJIError *error) {
        if (error.errorCode != ERR_Successed) {
            NSLog(@"Error: %@", error.errorDescription);
        }
    }];
    
    // Only do this 12 times
    if(photoCount <= 11) {
        [weakSelf performSelector: @selector(rotateGimbalAndTakePhoto) withObject:nil afterDelay:2];
        
    // Reset gimbal and pitch down 30 degrees then start over
    } else if (loopCount <= 3) {
        // This is used so we start the loop over when we take 12 photos
        photoCount = 0;
        // There are 4 loops of 12 photos
        loopCount = loopCount + 1;
        [self resetGimbalYaw:nil];
        [self pitchDown:nil];
        [weakSelf performSelector: @selector(rotateGimbalAndTakePhoto) withObject:nil afterDelay:2];
    // We're done capturing all the photos
    } else {
        panoInProgress = NO;
        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
        [self.startButton setBackgroundColor:[UIColor colorWithRed:13/255.0f green:112/255.0f blue:49/255.0f alpha:1.0f]];
        
        self.photoCountLabel.text = [NSString stringWithFormat: @"Photo: 48/48"];
        
        self.progressView.progress = 1.0;
        loopCount = 1;
        photoCount = 0;
        
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Panorama Complete!" message:@"Your 48 photos are now ready to be stitched into a panorama. Be sure to click the Reset button below to reset your gimbal yaw. You can use the Tilt buttons to set the proper tilt before beginning your next panorama." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        
        [self resetGimbalYaw:nil];
        
        [self resetGimbalPitch];
    }
    
}
*/
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

// Rotate right 15 degrees
- (IBAction)rotateGimbalRight:(id)sender {
    DJIGimbalRotation pitch = {YES, 0, RelativeAngle, RotationForward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationForward};
    DJIGimbalRotation yaw = {YES, 30, RelativeAngle, RotationForward};
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:nil];
}

// Rotate left 15 degrees
- (IBAction)rotateGimbalLeft:(id)sender {
    DJIGimbalRotation pitch = {YES, 0, RelativeAngle, RotationBackward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationBackward};
    DJIGimbalRotation yaw = {YES, 30, RelativeAngle, RotationBackward};
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:nil];
}

// Reset the gimbal yaw
- (IBAction)resetGimbalYaw:(id)sender {
    [_gimbal resetGimbalWithResult: nil];
}

// Down 30 degrees
- (IBAction)pitchDown:(id)sender {
    DJIGimbalRotation pitch = {YES, 30, RelativeAngle, RotationBackward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationBackward};
    DJIGimbalRotation yaw = {NO, 0, RelativeAngle, RotationBackward};
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:nil];
}

// Up 30 degrees
- (IBAction) pitchUp:(id)sender {
    DJIGimbalRotation pitch = {YES, 30, RelativeAngle, RotationForward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationForward};
    DJIGimbalRotation yaw = {NO, 0, RelativeAngle, RotationForward};
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:nil];
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
        //self.altitudeLabel.text =[NSString stringWithFormat: @"Altitude: %f m %d", inspireSystemState.altitude, loopCount];
        // Let's try using the attitude info to see if we can get it to populate
        self.altitudeLabel.text = [NSString stringWithFormat: @"%f", inspireSystemState.attitude.pitch];
    }
}

#pragma mark - DJIGimbalDelegate
-(void) gimbalController:(DJIGimbal *)controller didUpdateGimbalState:(DJIGimbalState*)gimbalState {
    self.yawLabel.text = [NSString stringWithFormat:@"Yaw: %0.1f", gimbalState.attitude.yaw];
    self.pitchLabel.text = [NSString stringWithFormat:@"Pitch: %0.1f", gimbalState.attitude.pitch];
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
    if (_drone.droneType == DJIDrone_Inspire) {
        if (systemState.workMode != CameraWorkModeCapture) {
            DJIInspireCamera* inspireCamera = (DJIInspireCamera*)_camera;
            [inspireCamera setCameraWorkMode:CameraWorkModeCapture withResult:nil];
        }
    }
}

@end
