//
//  ViewController.m
//  DronePan
//
//  Created by Dennis Baldwin on 1/23/16.
//  Copyright © 2016 Unmanned Airlines, LLC. All rights reserved.
//

#import "ViewController.h"
#import <DJISDK/DJISDK.h>
#import "VideoPreviewer.h"
#import "MBProgressHUD.h"
#import "Utils.h"

#define ENABLE_DEBUG_MODE 0

#define STANDARD_DELAY 1

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
                    fc.rollPitchControlMode = DJIVirtualStickRollPitchControlModeAngle;
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

    NSArray *yaw = aircraftYaw60;

    NSArray *pitch;

    if ([self productType] == PT_AIRCRAFT) {
        pitch = pitchAircraftYaw;
    } else if ([self productType] == PT_HANDHELD) {
        pitch = pitchOsmo;

        [self fetchGimbal].completionTimeForControlAngleAction = 0.5;
    } else {
        NSLog(@"Pano started with unknown type");

        return;
    }

    self.sequenceCount = ([pitch count] * [yaw count]) + 1;
    self.currentCount = 0;

    [self updateSequenceLabel];

    droneCmdsQueue = dispatch_queue_create("com.dronepan.queue", DISPATCH_QUEUE_SERIAL);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Set camera mode
        dispatch_sync(droneCmdsQueue, ^{
            [self setPhotoMode];
        });

        // Reset gimbal
        dispatch_sync(droneCmdsQueue, ^{
            [self resetGimbal];
        });

        // Short delay - allow you to get out of shot - should be GUI choice/display
        if ([self productType] == PT_HANDHELD) {
            [self waitFor:5];
        }

        // Loop through the gimbal pitches
        for (NSNumber *nPitch in pitch) {

            // Pitch the gimbal
            dispatch_sync(droneCmdsQueue, ^{
                [self setPitch:[nPitch floatValue]];
            });

            // Yaw loop and photo
            for (NSNumber *nYaw in yaw) {

                if ([self productType] == PT_AIRCRAFT) {

                    // Timer and run loop so that we can yaw to the desired location
                    dispatch_sync(droneCmdsQueue, ^{
                        NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:[nYaw floatValue]], @"yaw", nil];
                        NSTimer *sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(yaw:) userInfo:data repeats:YES];
                        [[NSRunLoop currentRunLoop] addTimer:sendTimer forMode:NSDefaultRunLoopMode];
                        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
                        [sendTimer invalidate];
                        sendTimer = nil;
                    });

                    dispatch_sync(droneCmdsQueue, ^{
                        [self waitFor:STANDARD_DELAY];
                    });
                } else if ([self productType] == PT_HANDHELD) {
                    dispatch_sync(droneCmdsQueue, ^{
                        [self setYaw:[nYaw floatValue]];
                    });
                }

                // Take the photo
                dispatch_sync(droneCmdsQueue, ^{
                    [self takeASnap];
                });
            }

        } // End pitch loop

        // Zenith (handheld) or Nadir (Aircraft) are both -90 pitch

        // Reset yaw to front for zenith/nadir
        dispatch_sync(droneCmdsQueue, ^{
            [self setYaw:0.0];
        });

        // Take the final zenith/nadir shot and then reset the gimbal back
        dispatch_sync(droneCmdsQueue, ^{
            [self setPitch:-90.0];
        });

        dispatch_sync(droneCmdsQueue, ^{
            [self takeASnap];
        });

        dispatch_sync(droneCmdsQueue, ^{
            [self resetGimbal];
        });

        dispatch_async(dispatch_get_main_queue(), ^{
            [[self sequenceLabel] setText:@"Sequence: Done"];
        });

        dispatch_async(dispatch_get_main_queue(), ^{
            [Utils displayToastOnApp:@"Completed pano"];
            
        });
    }); // End GCD

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


/*
static void (^gcdYawDrone)(float,DJIFlightController*)=^(float yaw,DJIFlightController *fc){
    
    DJIVirtualStickFlightControlData ctrlData = {0};
    ctrlData.pitch = 0;
    ctrlData.roll = 0;
    ctrlData.verticalThrottle = 0;
    ctrlData.yaw = 60;
    
    if (fc && fc.isVirtualStickControlModeAvailable) {
        [fc sendVirtualStickFlightControlData:ctrlData withCompletion:nil];
    }
    
};
*/

- (void)yaw:(NSTimer *)timer {

    NSDictionary *data = [timer userInfo];

    NSLog(@"Yawing: %@", [data objectForKey:@"yaw"]);

    DJIVirtualStickFlightControlData ctrlData = {0};
    ctrlData.pitch = 0;
    ctrlData.roll = 0;
    ctrlData.verticalThrottle = 0;
    ctrlData.yaw = [[data objectForKey:@"yaw"] floatValue];

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
    DJIGimbalAngleRotation yawR, pitchR = {};
    yawR.enabled = NO;
    pitchR.enabled = YES;
    pitchR.angle = pitch;

    [self setYaw:yawR pitch:pitchR];
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
    NSLog(@"Fetching camera");

    ProductType pt = [self productType];

    if (pt == PT_AIRCRAFT) {
        NSLog(@"Getting aircraft camera");
        return ((DJIAircraft *) self.product).camera;
    } else if (pt == PT_HANDHELD) {
        NSLog(@"Getting handheld camera");
        return ((DJIHandheld *) self.product).camera;
    }

    NSLog(@"No camera found");

    return nil;
}

- (DJIFlightController *)fetchFlightController {
    NSLog(@"Fetching flight controller");

    ProductType pt = [self productType];

    if (pt == PT_AIRCRAFT) {
        NSLog(@"Getting aircraft flight controller");
        return ((DJIAircraft *) self.product).flightController;
    }

    NSLog(@"No flight controller found");

    return nil;
}

- (DJIGimbal *)fetchGimbal {
    NSLog(@"Fetching gimbal");

    ProductType pt = [self productType];

    if (pt == PT_AIRCRAFT) {
        NSLog(@"Getting aircraft gimbal");
        return ((DJIAircraft *) self.product).gimbal;
    } else if (pt == PT_HANDHELD) {
        NSLog(@"Getting handheld gimbal");
        return ((DJIHandheld *) self.product).gimbal;
    }

    NSLog(@"No gimbal found");

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
        [DJISDKManager enterDebugModeWithDebugId:@"10.0.1.15"];
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
    self.headingLabel.text = [NSString stringWithFormat:@"Heading: %0.1f", fc.compass.heading];
}

@end
