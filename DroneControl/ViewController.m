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
    
    // Setup the google map view
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.868
                                                            longitude:151.2086
                                                                 zoom:12];
    
    self.progressView.progress = 0;
    panoInProgress = NO;
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) droneOnConnectionStatusChanged:(DJIConnectionStatus)status
{
    if (status == ConnectionSuccessed) {
        NSLog(@"Connection Success");
    }
    else if(status == ConnectionStartConnect)
    {
        NSLog(@"Start Reconnect");
    }
    else if(status == ConnectionBroken)
    {
        NSLog(@"Connection Broken");
    }
    else if (status == ConnectionFailed)
    {
        NSLog(@"Connection Failed");
    }
}

-(IBAction)setWorkModeAndBeginPano {
    
    // Let's start the panorama process
    if(panoInProgress == NO) {
        
        panoInProgress = YES;
        
        [self.startButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self.startButton setBackgroundColor:[UIColor redColor]];
        
        // Main loop counter, we'll try 3 loops with 12 photos in each row
        loopCount = 1;
        totalProgress = 0;
        self.progressView.progress = 0;
        totalPhotoCount = 0;
        
        [self resetGimbalYaw:nil];
        
        // Pause so that the gimbal can reset
        sleep(2);
        
        __weak typeof(self) weakSelf = self;
        
        // Set the camera work mode
        [_camera setCameraWorkMode:CameraWorkModeCapture withResult:^(DJIError *error) {
            if (error.errorCode != ERR_Successed) {
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Error setting camera work mode to capture" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            } else {
                [weakSelf rotateGimbalAndTakePhoto];
            }
         }];
    
    // Stop the pano
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm"
                                                    message:@"Are you sure you want to stop this panorama?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
        [alert show];
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


-(void)takeFirstRowPhotos {
    
}

-(void)takeSecondRowPhotos {
    
}

-(void)takeThirdRowPhotos {
    
}

/*
 We'll take a photo facing forward and then 11 photos at 30 degree increments after that
 */

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
        [self pitchDown30];
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
    }
    
    // Update battery status
    [_drone.smartBattery updateBatteryInfo:^(DJIError *error) {
        if (error.errorCode == ERR_Successed) {
            _batteryRemainingLabel.text = [NSString stringWithFormat: @"Battery: %ld%%", (long)_drone.smartBattery.remainPowerPercent];
        }
    }];
}

-(void) mainController:(DJIMainController*)mc didUpdateSystemState:(DJIMCSystemState*)state {
    /*DJIInspireMCSystemState* inspireSystemState = (DJIInspireMCSystemState*)state;
    {
        _altitudeLabel.text =[NSString stringWithFormat: @"Altitude: %f m %d", inspireSystemState.altitude, loopCount];
    }*/
}

// Rotate right 15 degrees
- (IBAction)rotateGimbalRight:(id)sender {
    DJIGimbalRotation pitch = {YES, 0, RelativeAngle, RotationForward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationForward};
    DJIGimbalRotation yaw = {YES, 15, RelativeAngle, RotationForward};
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:nil];
}

// Rotate left 15 degrees
- (IBAction)rotateGimbalLeft:(id)sender {
    DJIGimbalRotation pitch = {YES, 0, RelativeAngle, RotationBackward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationBackward};
    DJIGimbalRotation yaw = {YES, 15, RelativeAngle, RotationBackward};
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:nil];
}

// Reset the gimbal yaw
- (IBAction)resetGimbalYaw:(id)sender {
    [_gimbal resetGimbalWithResult: nil];
}

// Down 30 degrees
- (void) pitchDown30 {
    DJIGimbalRotation pitch = {YES, 60, RelativeAngle, RotationBackward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationBackward};
    DJIGimbalRotation yaw = {NO, 0, RelativeAngle, RotationBackward};
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:nil];
}

// Down 15 degrees
- (IBAction) pitchDown15:(id)sender {
    DJIGimbalRotation pitch = {YES, 15, RelativeAngle, RotationBackward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationBackward};
    DJIGimbalRotation yaw = {NO, 0, RelativeAngle, RotationBackward};
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:nil];
}

// Up 30 degrees
- (IBAction) pitchUp:(id)sender {
    DJIGimbalRotation pitch = {YES, 15, RelativeAngle, RotationForward};
    DJIGimbalRotation roll = {NO, 0, RelativeAngle, RotationForward};
    DJIGimbalRotation yaw = {NO, 0, RelativeAngle, RotationForward};
    [_gimbal setGimbalPitch:pitch Roll:roll Yaw:yaw withResult:nil];
}

// Hide the status bar
-(BOOL)prefersStatusBarHidden{
    return YES;
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
