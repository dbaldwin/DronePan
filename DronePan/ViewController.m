//
//  ViewController.m
//  DronePan
//
//  Created by Dennis Baldwin on 1/23/16.
//

#import "ViewController.h"
#import "SettingsViewController.h"
#import <DJISDK/DJISDK.h>
#import "VideoPreviewer.h"
#import "MBProgressHUD.h"
#import "Utils.h"

#define ENABLE_DEBUG_MODE 1

#define STANDARD_DELAY 3

@interface ViewController () <DJICameraDelegate, DJISDKManagerDelegate, DJIFlightControllerDelegate> {
    dispatch_queue_t droneCmdsQueue;
}

@property(nonatomic, strong) DJICamera *camera;
@property(weak, nonatomic) IBOutlet UIView *cameraView;
@property(weak, nonatomic) IBOutlet UIButton *startButton;
@property(nonatomic, weak) DJIBaseProduct *product;
@property(weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;
@property(weak, nonatomic) IBOutlet UILabel *headingLabel;
@property(weak, nonatomic) IBOutlet UILabel *sequenceLabel;
@property(nonatomic, assign) long sequenceCount;
@property(nonatomic, assign) long currentCount;
@property(nonatomic, assign) double currentHeading;
@property(nonatomic, assign) float yawSpeed;
@property(nonatomic, assign) int yawDestination;
@property(nonatomic, assign) NSTimer *yawTimer;

@property (weak, nonatomic) IBOutlet UITextView *debugTextView;

- (IBAction)startPano:(id)sender;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[VideoPreviewer instance] setView:self.cameraView];
    [[self sequenceLabel] setText:@"Sequence: ?/?"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[VideoPreviewer instance] setView:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSString *appKey = @"d6b78c9337f72fadd85d88e2";
    [DJISDKManager registerApp:appKey withDelegate:self];
}

// Hide status bar
-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// Let's detect the aircraft and then start the sequence
- (IBAction)startPano:(id)sender {

    [Utils displayToastOnApp:@"Starting pano"];

    NSString *model = self.product.model;

    // Display the aircract model we're connected to
    [self.connectionStatusLabel setText:model];

    if ([self productType] == PT_AIRCRAFT) {
        /* add if logic for I1 and P3
         here we would do aircraft yaw for P3 and give I1 users the option */

        DJIFlightController *fc = [self fetchFlightController];

        if (fc) {
            [fc enableVirtualStickControlModeWithCompletion:^(NSError *error) {
                if (error) {
                    NSString *msg = [NSString stringWithFormat:@"%@", error.description];
                    [Utils displayToastOnApp:msg];
                } else {
                    fc.yawControlMode = DJIVirtualStickYawControlModeAngularVelocity;
                    fc.rollPitchControlMode = DJIVirtualStickRollPitchControlModeVelocity;
                    fc.verticalControlMode = DJIVirtualStickVerticalControlModeVelocity;

                    [self doPanoLoop];
                }
            }];
        } else {
            // Do something or nothing here
            return;
        }
    } else {
        [self doPanoLoop];
    }

}

- (void)updateSequenceLabel {
    [[self sequenceLabel] setText:[NSString stringWithFormat:@"Sequence: %ld/%ld", self.currentCount, self.sequenceCount]];
}

- (void)doPanoLoop {

    NSArray *pitchGimbalYaw = @[@0, @-30, @-60];
    
    NSArray *pitchAircraftYaw = @[@0, @-30, @-60];

    NSArray *pitchOsmo = @[@-60, @-30, @0, @30];

    NSArray *gimYaw30 = @[@0, @30, @60, @90, @120, @150, @180, @210, @240, @270, @300, @330];

    NSArray *aircraftYaw30 = @[@0, @45, @45, @45, @45, @45, @45, @45, @45, @45, @45, @45];

    NSArray *gimYaw45 = @[@0, @45, @90, @135, @180, @225, @270, @315];

    NSArray *aircraftYaw45 = @[@0, @67.5, @67.5, @67.5, @67.5, @67.5, @67.5, @67.5];

    NSArray *gimYaw60 = @[@0, @60, @120, @180, @240, @300];

    NSArray *aircraftYaw60 = @[@0, @60, @120, @180, @-120, @-60];

    NSArray *pitch;
    
    int PHOTOS_PER_ROW = 6;
    
    int YAW_ANGLE = 360/PHOTOS_PER_ROW;
    
    NSMutableArray *yaw = [[NSMutableArray alloc] init];
    
    // Here we loop and create yaw angles bassed off the current aircraft heading
    // When a users clicks the start button that will be the point of reference from
    // Which we build the entire array of yaw angles
    for(int i=0; i<PHOTOS_PER_ROW; i++) {
        int destinationAngle = self.currentHeading + (YAW_ANGLE*(i+1));
        int convertedDestinationAngle = [self convertYawAngle: destinationAngle];
        [yaw addObject:[NSNumber numberWithInt: convertedDestinationAngle]];
        
        NSString *debug = [NSString stringWithFormat: @"%@degrees: %d\n", self.debugTextView.text, convertedDestinationAngle];
        [self.debugTextView setText: debug];
    }

    if ([self productType] == PT_AIRCRAFT) {
        pitch = pitchAircraftYaw;
    } else if ([self productType] == PT_HANDHELD) {
        pitch = pitchOsmo;
    } else {
        NSLog(@"Pano started with unknown type");

        return;
    }

    // Make pitching gimbal fast so we have time to shoot
    [self fetchGimbal].completionTimeForControlAngleAction = 0.5;
    
    self.sequenceCount = ([pitch count] * [yaw count]) + 1;
    self.currentCount = 0;

    [self updateSequenceLabel];

    droneCmdsQueue = dispatch_queue_create("com.dronepan.queue", DISPATCH_QUEUE_SERIAL);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Set camera mode
        dispatch_sync(droneCmdsQueue, ^{
            [self setPhotoMode];
        });

        // Reset gimbal - this will reset the gimbal yaw in case the user has changed it outside of DronePan
        dispatch_sync(droneCmdsQueue, ^{
            [self resetGimbal];
        });

        // Short delay - allow you to get out of shot - should be GUI choice/display
        [self waitFor:5];
        
        // We yaw the aircraft to its destination
        // For now we'll pitch gimbal back to 0 and restart the sequence
        // An improvement may be to move the gimbal in a "sawtooth" manner
        for (NSNumber *nYaw in yaw) {
            
            if ([self productType] == PT_AIRCRAFT) {
                
                self.yawSpeed = 60; // This represents 20m/sec
                self.yawDestination = [nYaw floatValue];
                
                // Calling this on a timer as it improves the accuracy of aircraft yaw
                dispatch_sync(droneCmdsQueue, ^{
                    NSTimer* sendTimer =[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(yawAircraftUsingVelocity:) userInfo:nil repeats:YES];
                    [[NSRunLoop currentRunLoop]addTimer:sendTimer forMode:NSDefaultRunLoopMode];
                    [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
                    [sendTimer invalidate];
                    sendTimer=nil;
                });
                
            } else if ([self productType] == PT_HANDHELD) {
                dispatch_sync(droneCmdsQueue, ^{
                    [self setYaw:[nYaw floatValue]];
                });
            }

            // Loop through the gimbal pitches
            for (NSNumber *nPitch in pitch) {

                // Pitch the gimbal
                dispatch_sync(droneCmdsQueue, ^{
                    [self setPitch:[nPitch floatValue]];
                });
                
                // Delay
                dispatch_sync(droneCmdsQueue, ^{
                    [self waitFor:STANDARD_DELAY];
                });
                
                // Take the photo
                dispatch_sync(droneCmdsQueue, ^{
                    [self takeASnap];
                });
                
                // Delay
                dispatch_sync(droneCmdsQueue, ^{
                    [self waitFor:STANDARD_DELAY];
                });
                
            } // End the gimbal pitch loop
            
        } // End yaw loop
        
        // Take the final zenith/nadir shot and then reset the gimbal back
        
        dispatch_sync(droneCmdsQueue, ^{
            [self setPitch:-90.0];
        });
        
        // Delay before we take the final photo
        dispatch_sync(droneCmdsQueue, ^{
            [self waitFor:STANDARD_DELAY];
        });
        
        dispatch_sync(droneCmdsQueue, ^{
            [self takeASnap];
        });
        
        // Delay before we reset the gimbal back to the horizon
        dispatch_sync(droneCmdsQueue, ^{
            [self waitFor:STANDARD_DELAY];
        });
        
        dispatch_sync(droneCmdsQueue, ^{
            [self setPitch:0.0];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self sequenceLabel] setText:@"Sequence: Done"];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [Utils displayToastOnApp:@"Completed pano"];
            
        });
        
    }); // End GCD

}

// Converts a 360 yaw angle to -180 to +180
-(int) convertYawAngle:(int)yawAngle {
    
    if(yawAngle > 180) {
        yawAngle = yawAngle - 180;
        yawAngle = 180 - yawAngle;
        yawAngle = yawAngle * -1;
    }
    
    if(yawAngle < -180) {
        yawAngle = yawAngle + 180; // -190 for example, which would = -10
        yawAngle = 180 + yawAngle; // 180-10 = an absolute angle of 170
    }
    
    return yawAngle;
}


#pragma mark GCD functions

- (void)resetGimbal {
    DJIGimbal *gimbal = [self fetchGimbal];

    if (gimbal) {
        [gimbal resetGimbalWithCompletion:^(NSError *_Nullable error) {
            if (error) {
                NSLog(@"Error resetting gimbal: %@", error);
            }
            
            [self waitFor:STANDARD_DELAY];
        }];
    }
}

- (void)setPhotoMode {
    DJICamera *camera = [self fetchCamera];

    if (camera) {
        [camera setCameraMode:DJICameraModeShootPhoto withCompletion:^(NSError *_Nullable error) {
            if (error) {
                [Utils displayToastOnApp:@"Couldn't set camera to photo mode"];
                NSLog(@"Unable to set camera to photo mode: %@", error);
            }
        }];
    }
}

// I still think this should be using some kind of GCD dispatch eventing - but for now leave it in
- (void)waitFor:(unsigned int)delay {
    sleep(delay);
}

- (void)yawAircraft:(NSTimer *)timer {
    
    NSDictionary *data = [timer userInfo];
    
    DJIVirtualStickFlightControlData ctrlData = {0};
    ctrlData.pitch = 0;
    ctrlData.roll = 0;
    ctrlData.verticalThrottle = 0;
    ctrlData.yaw = [[data objectForKey: @"yaw"] floatValue];
    
    DJIFlightController *fc = [self fetchFlightController];
    
    if (fc && fc.isVirtualStickControlModeAvailable) {
        [fc sendVirtualStickFlightControlData:ctrlData withCompletion:nil];
    }
}

- (void)yawAircraftUsingVelocity:(NSTimer *)timer {
    
    DJIVirtualStickFlightControlData ctrlData = {0};
    ctrlData.pitch = 0;
    ctrlData.roll = 0;
    ctrlData.verticalThrottle = 0;
    ctrlData.yaw = self.yawSpeed;
    
    DJIFlightController *fc = [self fetchFlightController];
    
    if (fc && fc.isVirtualStickControlModeAvailable) {
        [fc sendVirtualStickFlightControlData:ctrlData withCompletion:nil];
    }
}

- (void)takeASnap {
    DJICamera *camera = [self fetchCamera];

    if (camera) {
        [camera startShootPhoto:DJICameraShootPhotoModeSingle withCompletion:^(NSError *_Nullable error) {
            if (error) {
                [Utils displayToastOnApp:@"Error taking photo"];
                NSLog(@"Unable to take image %@", error);
            } else {
                self.currentCount++;
                [self updateSequenceLabel];
            }
            
            [self waitFor:STANDARD_DELAY];
        }];
    }
}

- (void)setYaw:(DJIGimbalAngleRotation)yaw pitch:(DJIGimbalAngleRotation)pitch {
    
    DJIGimbal *gimbal = [self fetchGimbal];

    if (gimbal) {
        DJIGimbalAngleRotation roll = {};
        roll.enabled = NO;

        [gimbal rotateGimbalWithAngleMode:DJIGimbalAngleModeAbsoluteAngle pitch:pitch roll:roll yaw:yaw withCompletion:^(NSError *_Nullable error) {
            if (error) {
                if (yaw.enabled) {
                    NSLog(@"Unable to yaw to yaw: %f,  %@", yaw.angle, error);
                }
                if (pitch.enabled) {
                    NSLog(@"Unable to pitch to pitch: %f,  %@", pitch.angle, error);
                }
            }
            
            [self waitFor:STANDARD_DELAY];
        }];
    }
}

- (void)setYaw:(float)yaw {
    DJIGimbalAngleRotation yawR, pitchR = {};
    yawR.angle = yaw;
    yawR.enabled = YES;
    pitchR.enabled = NO;

    [self setYaw:yawR pitch:pitchR];
}

- (void)setPitch:(float)pitch {
    
    NSLog(@"Pitching gimbal to %f", pitch);
    
    // For aircraft gimbal positive values represent clockwise (upward) rotation and negative values represent counter clockwise (downward) rotation
    DJIGimbalRotateDirection pitchDir = pitch > 0 ? DJIGimbalRotateDirectionClockwise : DJIGimbalRotateDirectionCounterClockwise;
    DJIGimbalAngleRotation yawR, pitchR = {};
    yawR.enabled = NO;
    pitchR.enabled = YES;
    pitchR.angle = pitch;
    pitchR.direction = pitchDir;

    [self setYaw:yawR pitch:pitchR];
}

- (IBAction)launchSettingsView:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SettingsViewController *settings = [storyboard instantiateViewControllerWithIdentifier:@"Settings"];
    [self presentViewController:settings animated:YES completion:nil];
}

#pragma mark - DJICameraDelegate

- (void)camera:(DJICamera *)camera didReceiveVideoData:(uint8_t *)videoBuffer length:(size_t)size {
    uint8_t *pBuffer = (uint8_t *) malloc(size);
    memcpy(pBuffer, videoBuffer, size);
    [[VideoPreviewer instance].dataQueue push:pBuffer length:(int) size];
}

#pragma mark Hardware helper methods

typedef enum {
    PT_AIRCRAFT,
    PT_HANDHELD,
    PT_UNKNOWN
} ProductType;

- (ProductType)productType {
    ProductType pt = PT_UNKNOWN;

    if (!self.product) {
        NSLog(@"Didn't find product");
    } else {
        if ([self.product isKindOfClass:[DJIAircraft class]]) {
            pt = PT_AIRCRAFT;
        } else if ([self.product isKindOfClass:[DJIHandheld class]]) {
            pt = PT_HANDHELD;
        }
    }

    return pt;
}

- (DJICamera *)fetchCamera {

    ProductType pt = [self productType];

    if (pt == PT_AIRCRAFT) {
        return ((DJIAircraft *) self.product).camera;
    } else if (pt == PT_HANDHELD) {
        return ((DJIHandheld *) self.product).camera;
    }

    return nil;
}

- (DJIFlightController *)fetchFlightController {

    ProductType pt = [self productType];

    if (pt == PT_AIRCRAFT) {
        return ((DJIAircraft *) self.product).flightController;
    }

    return nil;
}

- (DJIGimbal *)fetchGimbal {

    ProductType pt = [self productType];

    if (pt == PT_AIRCRAFT) {
        return ((DJIAircraft *) self.product).gimbal;
    } else if (pt == PT_HANDHELD) {
        return ((DJIHandheld *) self.product).gimbal;
    }

    return nil;
}

#pragma mark DJISDKManagerDelegate Method

// Called from startConnectionToProduct
- (void)sdkManagerProductDidChangeFrom:(DJIBaseProduct *_Nullable)oldProduct to:(DJIBaseProduct *_Nullable)newProduct {

    if (newProduct) {
        NSLog(@"New product");
        self.product = newProduct;

        [self.connectionStatusLabel setText:newProduct.model];

        __weak DJICamera *camera = [self fetchCamera];

        if (camera) {
            [camera setDelegate:self];
        }

        // Set the flight controller delegate only with aircraft. Ignore for Osmo.
        if ([self productType] == PT_AIRCRAFT) {
            // Setup delegate so we can get fc and compass updates
            DJIFlightController *fc = [self fetchFlightController];

            if (fc) {
                [fc setDelegate:self];
            }
        }
        
    } else {
        // Disconnected - let's update status label here
        [self.connectionStatusLabel setText:@"Disconnected"];

        NSLog(@"Product disconnected");

        self.product = nil;
    }
}

- (void)sdkManagerDidRegisterAppWithError:(NSError *)error {

    if (error) {
        NSString *msg = [NSString stringWithFormat:@"%@", error.description];
        [Utils displayToastOnApp:msg];
    } else {

#if ENABLE_DEBUG_MODE
        [DJISDKManager enterDebugModeWithDebugId:@"10.0.1.4"];
#else
        // This will call sdkManagerProductDidChangeFrom
        [DJISDKManager startConnectionToProduct];
#endif
        [[VideoPreviewer instance] start];

    }

    //[self showAlertViewWithTitle:@"Register App" withMessage:message];
}

#pragma mark DJIFlightControllerDelegate Methods

- (void)flightController:(DJIFlightController *)fc didUpdateSystemState:(DJIFlightControllerCurrentState *)state {
    self.currentHeading = fc.compass.heading;
    self.headingLabel.text = [NSString stringWithFormat:@"Heading: %0.1f, %d", self.currentHeading, self.yawDestination];
    
    int diff = abs(self.yawDestination) - abs([self convertYawAngle: self.currentHeading]);
    
    NSLog(@"Heading: %f, Destination: %d, Diff: %d", self.currentHeading, self.yawDestination, diff);
    
    self.yawSpeed = diff;
    
    // Check the current heading and invalidate the timer when we get to the destination
    /*if(self.currentHeading > self.yawDestination && self.currentHeading < (self.yawDestination+5)) {
        NSLog(@"Stopping yaw with currentHeading of: %f, and yaw of: %d", self.currentHeading, self.yawDestination);
        self.yawSpeed = 0; // Stop yawing
    }*/

}

@end
