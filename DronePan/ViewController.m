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

#import "DronePan-Swift.h"

#import <CocoaLumberjack/CocoaLumberjack.h>

#define ENABLE_DEBUG_MODE 0

#define STANDARD_DELAY 3

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@interface ViewController () <DJISDKManagerDelegate, DJIFlightControllerDelegate, GimbalControllerDelegate, CameraControllerDelegate, BatteryControllerDelegate, RemoteControllerDelegate> {
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
@property(nonatomic, assign) BOOL panoInProgress;
@property(nonatomic, assign) BOOL rcInFMode;

@property(nonatomic, strong) GimbalController *gimbalController;
@property(nonatomic, strong) dispatch_group_t gimbalDispatchGroup;

@property(nonatomic, strong) CameraController *cameraController;
@property(nonatomic, strong) dispatch_group_t cameraDispatchGroup;

@property (nonatomic, strong) DJIFlightController *flightController;

@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UILabel *acYawLabel;
@property (weak, nonatomic) IBOutlet UILabel *gimbalYawLabel;
@property (weak, nonatomic) IBOutlet UILabel *gimbalPitchLabel;
@property (weak, nonatomic) IBOutlet UILabel *gimbalRollLabel;

- (IBAction)startPano:(id)sender;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    DDLogInfo(@"Showing main window");
    
    [[VideoPreviewer instance] start];
    [[VideoPreviewer instance] setView:self.cameraView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[VideoPreviewer instance] setView:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    DDLogInfo(@"Register app");

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
    
    // TODO - this should be tested
#ifndef DEBUG
    [self.startButton setEnabled:NO];
#endif
    
    self.rcInFMode = NO;

    [self initLabels];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)initLabels {
    [self sequenceLabel].hidden = YES;
    [self batteryLabel].hidden = YES;
    [self altitudeLabel].hidden = YES;
    [self satelliteLabel].hidden = YES;
    [self distanceLabel].hidden = YES;
    
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
        DDLogInfo(@"Stopping pano from button");
        
        [ControllerUtils displayToastOnApp:@"Stopping pano. Please wait..."];
        
        self.panoInProgress = NO;
        
        return;
    }
    
    long panoCount = [ModelSettings numberOfImagesForCurrentSettings:self.product.model];
    
    if (![self.cameraController hasSpaceForPano:panoCount]) {
        DDLogDebug(@"Not enough space for \(panoCount) images");

        [ControllerUtils displayToastOnApp:[NSString stringWithFormat:@"Not enough space on card for %ld images", panoCount]];
        
        return;
    }
    
    // TODO - update for gimbal yaw for I1
    if ([self productType] == PT_AIRCRAFT) {

        if (![ControllerUtils isPhantom4:self.product.model]) {
            if (!self.rcInFMode) {
                DDLogDebug(@"Not in F mode");

                [ControllerUtils displayToastOnApp:[NSString stringWithFormat:@"Please set RC Flight Mode to F first."]];
            
                return;
            }
        }
    }
    
    self.panoInProgress = YES;
    
    [ControllerUtils displayToastOnApp:@"Starting pano"];

    NSString *model = self.product.model;

    DDLogInfo(@"Starting pano for %@", model);

    // Display the aircract model we're connected to
    [self.connectionStatusLabel setText:model];

    if ([self productType] == PT_AIRCRAFT) {
        /* add if logic for I1 and P3
         here we would do aircraft yaw for P3 and give I1 users the option */

        if (self.flightController) {
            [self.flightController enableVirtualStickControlModeWithCompletion:^(NSError *error) {
                if (error) {
                    DDLogWarn(@"Unable to set virtual stick mode %@", error);
                    [ControllerUtils displayToastOnApp:@"Unable to set virtual stick control mode"];
                } else {
                    self.flightController.yawControlMode = DJIVirtualStickYawControlModeAngularVelocity;
                    self.flightController.rollPitchControlMode = DJIVirtualStickRollPitchControlModeVelocity;
                    self.flightController.verticalControlMode = DJIVirtualStickVerticalControlModeVelocity;

                    [self doPanoLoop];
                }
            }];
        } else {
            DDLogWarn(@"No flight controller found - couldn't initialize");

            [ControllerUtils displayToastOnApp:@"Unable to initialize flight controller"];
            self.panoInProgress = NO;

            return;
        }

    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, [ModelSettings startDelay:model] * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self doPanoLoop];
        });
    }
}

- (void)updateSequenceLabel {
    NSString *seqText = [NSString stringWithFormat:@"Photo: %ld/%ld", self.currentCount, self.sequenceCount];
    
    DDLogDebug(@"Sequence Text: %@", seqText);
    
    [[self sequenceLabel] setText:seqText];
}

- (NSArray *)pitchesForLoopWithSkyRow:(BOOL)skyRow forType:(ProductType)productType andRowCount:(int)rowCount {
    int max = 0;
    int min = -60;
    
    int actualCount = rowCount;
    
    if (skyRow) {
        max = 30;
        actualCount = actualCount + 1;
    }
    
    double interval = (max - min) / (actualCount - 1);
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < actualCount; i++) {
        
        [values addObject:[NSNumber numberWithDouble:(max - (i*interval))]];
    }
    
    if (productType == PT_AIRCRAFT) {
        return [NSArray arrayWithArray:values];
    } else {
        return [NSArray arrayWithArray:[[values reverseObjectEnumerator] allObjects]];
    }
}

- (void)doPanoLoop {
    NSArray *pitches = [self pitchesForLoopWithSkyRow:[ModelSettings skyRow:self.product.model]
                                              forType:[self productType]
                                          andRowCount:(int)[ModelSettings numberOfRows:self.product.model]];

    // Switch from config when available
    bool aircraftYaw = YES;

    if ([self productType] == PT_AIRCRAFT) {
    } else if ([self productType] == PT_HANDHELD) {
        // Force gimbal yaw for handheld
        aircraftYaw = NO;
        
        // Osmo has no heading - set to 0
        // TODO - should also be done for gimbal yaw of AC when that is in place
        self.currentHeading = 0;
    } else {
        DDLogError(@"Pano started with unknown type");

        return;
    }

    NSArray *yaw = [self yawAnglesForCount:[ModelSettings photosPerRow:self.product.model] withHeading:[self headingTo360:self.currentHeading]];
    
    self.sequenceCount = ([pitches count] * [yaw count]) + 1;
    self.currentCount = 0;

    [self updateSequenceLabel];

    droneCmdsQueue = dispatch_queue_create("com.dronepan.queue", DISPATCH_QUEUE_SERIAL);

    DDLogDebug(@"PanoLoop: START");

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        // Set camera mode
        DDLogDebug(@"PanoLoop: setPhotoMode");
        [self setPhotoMode];

        // Reset gimbal - this will reset the gimbal yaw in case the user has changed it outside of DronePan
        DDLogDebug(@"PanoLoop: resetGimbal");
        [self resetGimbal];

        // We yaw the aircraft to its destination
        // For now we'll pitch gimbal back to 0 and restart the sequence
        // An improvement may be to move the gimbal in a "sawtooth" manner
        for (NSNumber *nYaw in yaw) {
            DDLogDebug(@"PanoLoop: YawLoop: %@", nYaw);
            
            // If the user has stopped the pano we'll break
            if(!self.panoInProgress) {
                DDLogDebug(@"PanoLoop: YawLoop: %@ -  pano not in progress", nYaw);

                break;
            }

            // Loop through the gimbal pitches
            for (NSNumber *nPitch in pitches) {
                DDLogDebug(@"PanoLoop: YawLoop: %@, PitchLoop: %@", nYaw, nPitch);
                
                // If the user has stopped the pano we'll break
                if(!self.panoInProgress) {
                    DDLogDebug(@"PanoLoop: YawLoop: %@, PitchLoop: %@ - pano not in progress", nYaw, nPitch);

                    break;
                }
                
                DDLogDebug(@"PanoLoop: YawLoop: %@, PitchLoop: %@ - set pitch", nYaw, nPitch);
                [self setPitch:[nPitch floatValue]];

                DDLogDebug(@"PanoLoop: YawLoop: %@, PitchLoop: %@ - take photo", nYaw, nPitch);
                [self takeASnap];
            } // End the gimbal pitch loop

            // Now we yaw after a column of photos has been taken
            if (aircraftYaw) {
                DDLogDebug(@"PanoLoop: YawLoop: %@ - AC yaw", nYaw);

                self.yawSpeed = 30; // This represents 30m/sec
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
                DDLogDebug(@"PanoLoop: YawLoop: %@ - gimbal yaw", nYaw);

                [self setYaw:[nYaw floatValue]];
            }
        } // End yaw loop

        // Take the final zenith/nadir shot and then reset the gimbal back
        // or we cancel the pano and still reset the gimbal
        if(self.panoInProgress) {
            DDLogDebug(@"PanoLoop: Zenith/Nadir - set pitch");
            [self setPitch:(float) -90.0];

            DDLogDebug(@"PanoLoop: Zenith/Nadir - take photo");
            [self takeASnap];
            
            [ControllerUtils displayToastOnApp:@"Completed pano"];
            
            self.panoInProgress = NO;
            
        } else { // The panorama has been aborted
            DDLogDebug(@"PanoLoop: was stopped OK");
            
            [ControllerUtils displayToastOnApp: @"Pano stopped successfully"];
            
        }
        
        DDLogDebug(@"PanoLoop: reset gimbal");
        [self resetGimbal];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self sequenceLabel] setText:@"Photo: Done"];
        });

        DDLogDebug(@"PanoLoop: END");

        self.panoInProgress = NO;

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
    DDLogDebug(@"Set photo mode");
    
    if (self.cameraController) {
        dispatch_group_enter(self.cameraDispatchGroup);
        DDLogDebug(@"Set photo mode - send");
        [self.cameraController setPhotoMode];
        dispatch_group_wait(self.cameraDispatchGroup, DISPATCH_TIME_FOREVER);
        DDLogDebug(@"Set photo mode - done");
    }
}

- (void)takeASnap {
    DDLogDebug(@"Take a snap");

    if (self.cameraController) {
        dispatch_group_enter(self.cameraDispatchGroup);
        DDLogDebug(@"Take a snap - send");
        [self.cameraController takeASnap];
        dispatch_group_wait(self.cameraDispatchGroup, DISPATCH_TIME_FOREVER);
        DDLogDebug(@"Take a snap - done");
    }
}

- (void)yawAircraftUsingVelocity:(NSTimer *)timer {

    DJIVirtualStickFlightControlData ctrlData = {0};
    ctrlData.pitch = 0;
    ctrlData.roll = 0;
    ctrlData.verticalThrottle = 0;
    ctrlData.yaw = (float) self.yawSpeed;

    if (self.flightController && self.flightController.isVirtualStickControlModeAvailable) {
        [self.flightController sendVirtualStickFlightControlData:ctrlData withCompletion:nil];
    }
}

- (void)resetGimbal {
    DDLogDebug(@"Reset gimbal");
    if (self.gimbalController) {
        dispatch_group_enter(self.gimbalDispatchGroup);
        DDLogDebug(@"Reset gimbal - send");
        [self.gimbalController reset];
        dispatch_group_wait(self.gimbalDispatchGroup, DISPATCH_TIME_FOREVER);
        DDLogDebug(@"Reset gimbal - done");
    }
}

- (void)setYaw:(float)yaw {
    DDLogDebug(@"Set yaw %f", yaw);
    if (self.gimbalController) {
        dispatch_group_enter(self.gimbalDispatchGroup);
        DDLogDebug(@"Set yaw %f - send", yaw);
        [self.gimbalController setYaw:yaw];
        dispatch_group_wait(self.gimbalDispatchGroup, DISPATCH_TIME_FOREVER);
        DDLogDebug(@"Set yaw %f - done", yaw);
    }
}

- (void)setPitch:(float)pitch {
    DDLogDebug(@"Set pitch %f", pitch);
    if (self.gimbalController) {
        dispatch_group_enter(self.gimbalDispatchGroup);
        DDLogDebug(@"Set pitch %f - send", pitch);
        [self.gimbalController setPitch:pitch];
        dispatch_group_wait(self.gimbalDispatchGroup, DISPATCH_TIME_FOREVER);
        DDLogDebug(@"Set pitch %f - done", pitch);
    }
}

- (IBAction)launchSettingsView:(id)sender {
    [self performSegueWithIdentifier:@"launchSettings" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    SettingsViewController *settings = [segue destinationViewController];

#ifdef DEBUG
    if (self.product.model.length == 0) {
        settings.model = @"Simulator";
        settings.productType = PT_AIRCRAFT;
    } else {
        settings.model = self.product.model;
        settings.productType = [self productType];
    }
#else
    if (self.product.model.length > 0) {
        settings.model = self.product.model;
        settings.productType = [self productType];
    }
#endif
}

// Override setter
- (void)setPanoInProgress:(BOOL)panoInProgress {
    self->_panoInProgress = panoInProgress;
    
    if (!panoInProgress) {
        if (self.cameraController) {
            [self.cameraController setStatus:ControllerStatusStopping];
        }
        if (self.gimbalController) {
            [self.gimbalController setStatus:ControllerStatusStopping];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.startButton setBackgroundImage:[UIImage imageNamed:@"Start"] forState:UIControlStateNormal];
            
            [UIView animateWithDuration:2 animations:^{
                [self.infoView setAlpha:0];
            }];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.startButton setBackgroundImage:[UIImage imageNamed:@"Stop"] forState:UIControlStateNormal];

            [self.acYawLabel setText:[NSString stringWithFormat:@"----"]];
            [self.gimbalYawLabel setText:[NSString stringWithFormat:@"----"]];
            [self.gimbalRollLabel setText:[NSString stringWithFormat:@"----"]];
            [self.gimbalPitchLabel setText:[NSString stringWithFormat:@"----"]];
            
            [UIView animateWithDuration:2 animations:^{
                [self.infoView setAlpha:0.5];
            }];
        });
    }
}

#pragma mark - BatteryControllerDelegate

- (void)batteryControllerPercentUpdated:(NSInteger)batteryPercent {
    [[self batteryLabel] setText:[NSString stringWithFormat: @"Batt: %ld%%", (long)batteryPercent]];
}

- (void)batteryControllerTemperatureUpdated:(NSInteger)batteryTemperature {
    // TODO
}

#pragma mark - RemoteControllerDelegate

- (void)remoteControllerSetFlightMode:(enum FlightMode)mode {
    if (mode == FlightModeFunction) {
        self.rcInFMode = YES;
    } else {
        self.rcInFMode = NO;
    }
}

- (void)remoteControllerBatteryPercentUpdated:(NSInteger)batteryPercent {
    // TODO
}

#pragma mark - GimbalControllerDelegate

- (void)gimbalControllerCompleted {
    DDLogDebug(@"Gimbal signalled complete");

    dispatch_async(droneCmdsQueue, ^{
        dispatch_group_leave(self.gimbalDispatchGroup);
    });
}

- (void)gimbalControllerAborted:(NSString *) reason {
    DDLogWarn(@"Gimbal signalled abort %@", reason);
    
    [ControllerUtils displayToastOnApp:reason];

    dispatch_async(droneCmdsQueue, ^{
        self.panoInProgress = NO;

        dispatch_group_leave(self.gimbalDispatchGroup);
    });
}

- (void)gimbalMoveOutOfRange:(NSString *) reason {
    DDLogDebug(@"Gimbal signalled out of range %@", reason);
    
    [ControllerUtils displayToastOnApp:reason];

    // We signal and ignore - let's try the next move
    dispatch_async(droneCmdsQueue, ^{
        dispatch_group_leave(self.gimbalDispatchGroup);
    });
}

- (void)gimbalAttitudeChangedWithPitch:(float)pitch yaw:(float)yaw roll:(float)roll {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gimbalPitchLabel setText:[NSString stringWithFormat:@"%.2f", pitch]];
        [self.gimbalYawLabel setText:[NSString stringWithFormat:@"%.2f", yaw]];
        [self.gimbalRollLabel setText:[NSString stringWithFormat:@"%.2f", roll]];
    });
}

#pragma mark - CameraControllerDelegate

- (void)cameraReceivedVideo:(uint8_t *)videoBuffer size:(NSInteger)size {
    uint8_t* pBuffer = (uint8_t*)malloc(size);
    memcpy(pBuffer, videoBuffer, size);

    if(![[[VideoPreviewer instance] dataQueue] isFull]){
        [[VideoPreviewer instance] push:pBuffer length:(int)size];
    }
}

- (void)cameraControllerReset {
    DDLogDebug(@"Camera signalled reset");
    
    dispatch_async(droneCmdsQueue, ^{
        dispatch_group_leave(self.cameraDispatchGroup);
    });
}

- (void)cameraControllerCompleted:(BOOL)shotTaken {
    DDLogDebug(@"Camera signalled complete with shot taken %d", shotTaken);
    
    if (shotTaken) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentCount = self.currentCount + 1;
            [self updateSequenceLabel];
        });
    }
    
    dispatch_async(droneCmdsQueue, ^{
        dispatch_group_leave(self.cameraDispatchGroup);
    });
}

- (void)cameraControllerAborted:(NSString *) reason {
    DDLogWarn(@"Camera signalled abort %@", reason);
    
    [ControllerUtils displayToastOnApp:reason];
    
    dispatch_async(droneCmdsQueue, ^{
        self.panoInProgress = NO;

        dispatch_group_leave(self.cameraDispatchGroup);
    });
}

- (void)cameraControllerInError:(NSString *) reason {
    DDLogWarn(@"Camera signalled error %@", reason);

    [ControllerUtils displayToastOnApp:reason];
    
    if (self.panoInProgress) {
        if (droneCmdsQueue != nil) {
            dispatch_async(droneCmdsQueue, ^{
                self.panoInProgress = NO;
            });
        } else {
            self.panoInProgress = NO;
        }
    }
    
    [[self startButton] setEnabled:NO];
}

- (void)cameraControllerOK:(BOOL) fromError {
    DDLogDebug(@"Camera signalled OK");

    if (fromError) {
        [ControllerUtils displayToastOnApp:@"Camera is ready"];
    }

    [[self startButton] setEnabled:YES];
}

#pragma mark Hardware helper methods

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

#pragma mark DJISDKManagerDelegate Method

// Called from startConnectionToProduct
- (void)sdkManagerProductDidChangeFrom:(DJIBaseProduct *_Nullable)oldProduct to:(DJIBaseProduct *_Nullable)newProduct {
    DDLogInfo(@"Change of product");

    if (newProduct) {
        DDLogInfo(@"New product %@", newProduct.model);

        self.product = newProduct;

        DDLogDebug(@"Trying to set hardware decoding");
        BOOL hardwareDecodeSupported = [[VideoPreviewer instance] setDecoderWithProduct:newProduct andDecoderType:VideoPreviewerDecoderTypeHardwareDecoder];
        
        if (!hardwareDecodeSupported) {
            DDLogDebug(@"Hardware decoding failed - try to set software decoding");
            BOOL softwareDecodeSupported = [[VideoPreviewer instance] setDecoderWithProduct:newProduct andDecoderType:VideoPreviewerDecoderTypeSoftwareDecoder];
            
            if (!softwareDecodeSupported) {
                DDLogError(@"OK - so it doesn't support hardware or software - no idea what to do now");
            }
        }
        
        [self.connectionStatusLabel setText:newProduct.model];
        [self.startButton setEnabled:YES];

#ifndef DEBUG
        [self.settingsButton setEnabled:YES];
#endif

        ProductType pt = [self productType];

        DJIGimbal *gimbal;
        DJICamera *camera;
        DJIBattery *battery;
        DJIFlightController *flightController;

        [self sequenceLabel].hidden = NO;
        [self batteryLabel].hidden = NO;

        if (pt == PT_AIRCRAFT) {
            camera = ((DJIAircraft *) self.product).camera;
            gimbal = ((DJIAircraft *) self.product).gimbal;
            battery = ((DJIAircraft *) self.product).battery;
            flightController = ((DJIAircraft *) self.product).flightController;
            
            DJIRemoteController *remote = ((DJIAircraft *) self.product).remoteController;
            
            if (remote) {
                RemoteController *remoteController = [[RemoteController alloc] initWithRemote:remote];
                remoteController.delegate = self;
            }

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
            
            self.rcInFMode = NO;
        }

        NSMutableArray *missing = [[NSMutableArray alloc] init];
        
        if (flightController) {
            // TODO - this should not be a direct property but wrapped like the others
            self.flightController = flightController;
            self.flightController.delegate = self;
        } else {
            if (pt == PT_AIRCRAFT) {
                DDLogError(@"No FC found");
                [missing addObject:@"Flight Controller"];
            }
        }

        if (camera) {
            self.cameraController = [[CameraController alloc] initWithCamera:camera];
            self.cameraController.delegate = self;
        } else {
            DDLogError(@"No camera found");
            [missing addObject:@"Camera"];
        }

        if (gimbal) {
            self.gimbalController = [[GimbalController alloc] initWithGimbal:gimbal supportsSDKYaw:![ControllerUtils isPhantom4:self.product.model]];
            self.gimbalController.delegate = self;
        } else {
            DDLogError(@"No gimbal found");
            [missing addObject:@"Gimbal"];
        }
        
        if (battery) {
            BatteryController *batteryController = [[BatteryController alloc] initWithBattery: battery];
            batteryController.delegate = self;
        } else {
            DDLogError(@"No battery found");
            [missing addObject:@"Battery"];
        }
        
        if ([missing count] > 0) {
            [ControllerUtils displayToastOnApp:[NSString stringWithFormat:@"Device seen but missing %@", [missing componentsJoinedByString:@", "]]];
        }
    } else {
        DDLogInfo(@"Disconnected");
        // Disconnected - let's update status label here
        [self.connectionStatusLabel setText:@"Disconnected"];
        [self.startButton setEnabled:NO];
#ifndef DEBUG
        [self.settingsButton setEnabled:NO];
#endif

        self.rcInFMode = NO;

        [self initLabels];

        NSLog(@"Product disconnected");

        self.product = nil;
        self.cameraController = nil;
        self.gimbalController = nil;
        
        self.flightController = nil;
    }
}

- (void)sdkManagerDidRegisterAppWithError:(NSError *)error {
    DDLogInfo(@"Registered");

    if (error) {
        DDLogWarn(@"Registered error %@", error);

        NSString *msg = [NSString stringWithFormat:@"%@", error.description];
        [ControllerUtils displayToastOnApp:msg];
    } else {
        DDLogDebug(@"Connecting to product");

#if ENABLE_DEBUG_MODE
        DDLogDebug(@"Connecting to debug bridge");
        [DJISDKManager enterDebugModeWithDebugId:@"10.0.1.18"];
#else
        // This will call sdkManagerProductDidChangeFrom
        DDLogDebug(@"Connecting to real product");
        [DJISDKManager startConnectionToProduct];
#endif
    }

    //[self showAlertViewWithTitle:@"Register App" withMessage:message];
}

#pragma mark DJIFlightControllerDelegate Methods

- (void)flightController:(DJIFlightController *)fc didUpdateSystemState:(DJIFlightControllerCurrentState *)state {
    DDLogVerbose(@"FC didUpdateSystemState");

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

    [self.acYawLabel setText:[NSString stringWithFormat:@"%.2f", self.currentHeading]];
}

@end
