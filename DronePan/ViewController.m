/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "ViewController.h"
#import <DJISDK/DJISDK.h>
#import "VideoPreviewer.h"
#import "Utils.h"

#import "DronePan-Swift.h"

#define ENABLE_DEBUG_MODE 0

#define STANDARD_DELAY 3

@interface ViewController () <DJISDKManagerDelegate, DJIFlightControllerDelegate, DJIBatteryDelegate, GimbalControllerDelegate, CameraControllerDelegate> {
    dispatch_queue_t droneCmdsQueue;
}

@property(nonatomic, weak) DJIBaseProduct *product;

@property(weak, nonatomic) IBOutlet UIView *cameraView;
@property(weak, nonatomic) IBOutlet UIButton *startButton;
@property(weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *altitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *satelliteLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;

@property(weak, nonatomic) IBOutlet UILabel *sequenceLabel;


@property(nonatomic, assign) long sequenceCount;
@property(nonatomic, assign) long currentCount;
@property(nonatomic, assign) double currentHeading;
@property(nonatomic, assign) double yawSpeed;
@property(nonatomic, assign) double yawDestination;
@property(nonatomic, assign) NSTimer *yawTimer;
@property(nonatomic, assign) CLLocationCoordinate2D aircraftLocation;
@property(nonatomic, assign) bool panoInProgress;

@property(nonatomic, strong) GimbalController *gimbalController;
@property(nonatomic, strong) dispatch_group_t gimbalDispatchGroup;
@property(nonatomic, strong) CameraController *cameraController;
@property(nonatomic, strong) dispatch_group_t cameraDispatchGroup;

- (IBAction)startPano:(id)sender;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[VideoPreviewer instance] setView:self.cameraView];
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
- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.gimbalDispatchGroup = dispatch_group_create();
    self.cameraDispatchGroup = dispatch_group_create();
    
    // Temporarily disabling during testing
    //[self.startButton setEnabled:NO];
    
    [self initLabels];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initLabels {
    [[self altitudeLabel] setText:@"Alt: -"];
    [[self satelliteLabel] setText:@"Sats: -"];
    [[self batteryLabel] setText:@"Batt: -"];
    [[self distanceLabel] setText:@"Dist: -"];
    [[self sequenceLabel] setText:@"Photo: -/-"];
}

// Let's detect the aircraft and then start the sequence
- (IBAction)startPano:(id)sender {

    // Need to get this all hooked up so we can stop the pano
    if (self.panoInProgress) {
        
        [self.startButton setBackgroundImage:[UIImage imageNamed:@"Start"] forState:UIControlStateNormal];
        
        [Utils displayToastOnApp:@"Stopping pano"];
        
        self.panoInProgress = false;
        
        return;
        
    }
    
    
    self.panoInProgress = true;
    
    [self.startButton setBackgroundImage:[UIImage imageNamed:@"Stop"] forState:UIControlStateNormal];

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

    NSArray *pitchAircraftYaw = @[@0, @-30, @-60];

    NSArray *pitchOsmo = @[@-60, @-30, @0, @30];

    NSArray *pitch;
    
    long PHOTOS_PER_ROW = [ModelSettings photosPerRow:self.product.model];
    
    // Switch from config when available
    bool aircraftYaw = YES;

    if ([self productType] == PT_AIRCRAFT) {
        pitch = pitchAircraftYaw;
    } else if ([self productType] == PT_HANDHELD) {
        pitch = pitchOsmo;
        
        // Force gimbal yaw for handheld
        aircraftYaw = NO;
        
        // Osmo has no heading - set to 0
        // TODO - should also be done for gimbal yaw of AC when that is in place
        self.currentHeading = 0;
    } else {
        NSLog(@"Pano started with unknown type");

        return;
    }

    NSArray *yaw = [self yawAnglesForCount:PHOTOS_PER_ROW withHeading:[self headingTo360:self.currentHeading]];
    
    self.sequenceCount = ([pitch count] * [yaw count]) + 1;
    self.currentCount = 0;

    [self updateSequenceLabel];

    droneCmdsQueue = dispatch_queue_create("com.dronepan.queue", DISPATCH_QUEUE_SERIAL);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        // Set camera mode
        [self setPhotoMode];

        // Reset gimbal - this will reset the gimbal yaw in case the user has changed it outside of DronePan
        [self resetGimbal];

        // We yaw the aircraft to its destination
        // For now we'll pitch gimbal back to 0 and restart the sequence
        // An improvement may be to move the gimbal in a "sawtooth" manner
        for (NSNumber *nYaw in yaw) {

            // Loop through the gimbal pitches
            for (NSNumber *nPitch in pitch) {
                [self setPitch:[nPitch floatValue]];
                [self takeASnap];
            } // End the gimbal pitch loop

            // Now we yaw after a column of photos has been taken
            if (aircraftYaw) {

                self.yawSpeed = 30; // This represents 25m/sec
                self.yawDestination = [nYaw floatValue];

                // Calling this on a timer as it improves the accuracy of aircraft yaw
                dispatch_sync(droneCmdsQueue, ^{
                    NSTimer *sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(yawAircraftUsingVelocity:) userInfo:nil repeats:YES];
                    [[NSRunLoop currentRunLoop] addTimer:sendTimer forMode:NSDefaultRunLoopMode];
                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
                    [sendTimer invalidate];
                    sendTimer = nil;
                });

            } else {
                [self setYaw:[nYaw floatValue]];
            }
        } // End yaw loop

        // Take the final zenith/nadir shot and then reset the gimbal back
        [self setPitch:(float) -90.0];
        [self takeASnap];
        [self resetGimbal];

        dispatch_async(dispatch_get_main_queue(), ^{
            [[self sequenceLabel] setText:@"Sequence: Done"];
        });

        [Utils displayToastOnApp:@"Completed pano"];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.startButton setTitle:@"Start" forState:UIControlStateNormal];
        });

    }); // End GCD

}

- (NSArray *)yawAnglesForCount:(long)count withHeading:(double)heading {
    
    double YAW_ANGLE = 360 / count;

    NSMutableArray *yaw = [[NSMutableArray alloc] init];

    // Here we loop and create yaw angles based off the current aircraft heading
    // When a users clicks the start button that will be the point of reference from
    // Which we build the entire array of yaw angles
    for (int i = 0; i < count; i++) {
        double destinationAngle = heading + (YAW_ANGLE * (i + 1)); // The +1 makes sure the first destination is not the current heading

        if (destinationAngle > 360)
            destinationAngle = destinationAngle - 360;

        [yaw addObject:@(destinationAngle)];
    }

    return yaw;
}

- (double)headingTo360:(double)heading {
    if (heading >= 0) {
        return heading;
    } else {
        return heading + 360;
    }
}

#pragma mark GCD functions

- (void)setPhotoMode {
    if (self.cameraController) {
        dispatch_group_enter(self.cameraDispatchGroup);
        [self.cameraController setPhotoMode];
        dispatch_group_wait(self.cameraDispatchGroup, DISPATCH_TIME_FOREVER);
    }
}

- (void)takeASnap {
    if (self.cameraController) {
        dispatch_group_enter(self.cameraDispatchGroup);
        [self.cameraController takeASnap];
        dispatch_group_wait(self.cameraDispatchGroup, DISPATCH_TIME_FOREVER);
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
    ctrlData.yaw = [data[@"yaw"] floatValue];

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
    ctrlData.yaw = (float) self.yawSpeed;

    DJIFlightController *fc = [self fetchFlightController];

    if (fc && fc.isVirtualStickControlModeAvailable) {
        [fc sendVirtualStickFlightControlData:ctrlData withCompletion:nil];
    }
}

- (void)resetGimbal {
    if (self.gimbalController) {
        dispatch_group_enter(self.gimbalDispatchGroup);
        [self.gimbalController reset];
        dispatch_group_wait(self.gimbalDispatchGroup, DISPATCH_TIME_FOREVER);
    }
}

- (void)setYaw:(float)yaw {
    if (self.gimbalController) {
        dispatch_group_enter(self.gimbalDispatchGroup);
        [self.gimbalController setYaw:yaw];
        dispatch_group_wait(self.gimbalDispatchGroup, DISPATCH_TIME_FOREVER);
    }
}

- (void)setPitch:(float)pitch {
    if (self.gimbalController) {
        dispatch_group_enter(self.gimbalDispatchGroup);
        [self.gimbalController setPitch:pitch];
        dispatch_group_wait(self.gimbalDispatchGroup, DISPATCH_TIME_FOREVER);
    }
}

- (IBAction)launchSettingsView:(id)sender {
    [self performSegueWithIdentifier:@"launchSettings" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    SettingsViewController *settings = [segue destinationViewController];
    
    if(self.product.model.length == 0)
        settings.model = @"Simulator"; // This is for testing in dev env
    else
        settings.model = self.product.model; // Pass the model to Settings VC
}

#pragma mark - GimbalControllerDelegate

- (void)gimbalControllerCompleted {
    NSLog(@"Gimbal signalled complete");

    dispatch_async(droneCmdsQueue, ^{
        dispatch_group_leave(self.gimbalDispatchGroup);
    });
}

- (void)gimbalControllerAborted {
    NSLog(@"Gimbal signalled abort");
    
    [Utils displayToastOnApp:@"Aborted - gimbal move failed"];

    dispatch_async(droneCmdsQueue, ^{
        self.panoInProgress = false;

        dispatch_group_leave(self.gimbalDispatchGroup);
    });
}

#pragma mark - CameraControllerDelegate

- (void)cameraReceivedVideo:(uint8_t *)videoBuffer size:(NSInteger)size {
    uint8_t *pBuffer = (uint8_t *) malloc(size);
    memcpy(pBuffer, videoBuffer, size);
    [[VideoPreviewer instance].dataQueue push:pBuffer length:(int) size];
}

- (void)cameraControllerReset {
    NSLog(@"Camera signalled reset");
    
    dispatch_async(droneCmdsQueue, ^{
        dispatch_group_leave(self.cameraDispatchGroup);
    });
}

- (void)cameraControllerCompleted {
    NSLog(@"Camera signalled complete");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentCount = self.currentCount + 1;
        [self updateSequenceLabel];
    });
    
    dispatch_async(droneCmdsQueue, ^{
        dispatch_group_leave(self.cameraDispatchGroup);
    });
}

- (void)cameraControllerAborted {
    NSLog(@"Camera signalled abort");
    
    [Utils displayToastOnApp:@"Aborted - photo not saved"];

    dispatch_async(droneCmdsQueue, ^{
        self.panoInProgress = false;

        dispatch_group_leave(self.cameraDispatchGroup);
    });
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

- (DJIFlightController *)fetchFlightController {

    ProductType pt = [self productType];

    if (pt == PT_AIRCRAFT) {
        return ((DJIAircraft *) self.product).flightController;
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
        [self.startButton setEnabled:YES];

        // Set the flight controller delegate only with aircraft. Ignore for Osmo.
        if ([self productType] == PT_AIRCRAFT) {
            // Setup delegate so we can get fc and compass updates
            DJIFlightController *fc = [self fetchFlightController];

            if (fc) {
                [fc setDelegate:self];
            }
        }

        ProductType pt = [self productType];

        DJIGimbal *gimbal;
        DJICamera *camera;
        DJIBattery *battery;

        if (pt == PT_AIRCRAFT) {
            camera = ((DJIAircraft *) self.product).camera;
            gimbal = ((DJIAircraft *) self.product).gimbal;
            battery = ((DJIAircraft*) self.product).battery;

            [self altitudeLabel].hidden = NO;
            [self satelliteLabel].hidden = NO;
            [self distanceLabel].hidden = NO;
        } else if (pt == PT_HANDHELD) {
            camera = ((DJIHandheld *) self.product).camera;
            gimbal = ((DJIHandheld *) self.product).gimbal;
            battery = ((DJIHandheld*) self.product).battery;
            
            [self altitudeLabel].hidden = YES;
            [self satelliteLabel].hidden = YES;
            [self distanceLabel].hidden = YES;
        }

        if (camera) {
            self.cameraController = [[CameraController alloc] initWithCamera:camera];
            self.cameraController.delegate = self;
        }

        if (gimbal) {
            self.gimbalController = [[GimbalController alloc] initWithGimbal:gimbal];
            self.gimbalController.delegate = self;
        }
        
        // Should refactor into its own controller to get other battery delegate updates
        if (battery) {
            [battery setDelegate: self];
        }
        
    } else {
        // Disconnected - let's update status label here
        [self.connectionStatusLabel setText:@"Disconnected"];
        [self.startButton setEnabled:NO];


        NSLog(@"Product disconnected");

        self.product = nil;
        self.cameraController = nil;
        self.gimbalController = nil;
    }
}

- (void)sdkManagerDidRegisterAppWithError:(NSError *)error {

    if (error) {
        NSString *msg = [NSString stringWithFormat:@"%@", error.description];
        [Utils displayToastOnApp:msg];
    } else {

#if ENABLE_DEBUG_MODE
        [DJISDKManager enterDebugModeWithDebugId:@"10.0.1.18"];
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

    self.aircraftLocation = state.aircraftLocation;

    self.currentHeading = [self headingTo360:fc.compass.heading];
    
    [[self altitudeLabel] setText: [NSString stringWithFormat: @"Alt: %dm", (int)state.altitude]];
    
    [[self satelliteLabel] setText: [NSString stringWithFormat: @"Sats: %d", state.satelliteCount]];
    
    // Calculate the distance from home
    CLLocation *homeLocation = [[CLLocation alloc] initWithLatitude: state.homeLocation.latitude longitude: state.homeLocation.longitude];
    CLLocation *aircraftLocation = [[CLLocation alloc] initWithLatitude: state.aircraftLocation.latitude longitude: state.aircraftLocation.longitude];
    CLLocationDistance dist = [homeLocation distanceFromLocation:aircraftLocation];
    [[self distanceLabel] setText: [NSString stringWithFormat: @"Dist: %dm", (int)dist]];
    
    
    // Calculate the yaw speed so we can slow the rotation as the aircraft reaches its destination
    double diff;

    if (self.yawDestination > self.currentHeading) {
        diff = fabs(self.yawDestination) - fabs(self.currentHeading);
        self.yawSpeed = diff * 0.5;
    } else { // This happens when the current heading is 340 and destination is 40, for example
        diff = fabs(self.currentHeading) - fabs(self.yawDestination);
        self.yawSpeed = fmod(360.0, diff) * 0.5;
    }

}

#pragma mark - DJIBatteryDelegate

-(void) battery:(DJIBattery *)battery didUpdateState:(DJIBatteryState *)batteryState {
    [[self batteryLabel] setText:[NSString stringWithFormat: @"Batt: %ld%%", (long)batteryState.batteryEnergyRemainingPercent]];
}


@end
