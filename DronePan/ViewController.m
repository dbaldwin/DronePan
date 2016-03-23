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

@interface ViewController ()<DJICameraDelegate, DJISDKManagerDelegate> {
    dispatch_queue_t droneCmdsQueue;
}

@property (nonatomic, strong) DJICamera* camera;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property(nonatomic, weak) DJIBaseProduct* product;
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;

- (IBAction)startPano:(id)sender;

@end

@implementation ViewController

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    [[VideoPreviewer instance] setView:self.cameraView];
}

- (void)viewWillDisappear:(BOOL)animated
{
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
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Let's detect the aircraft and then start the sequence
- (IBAction)startPano:(id)sender {
    
    [Utils displayToastOnApp: @"Starting pano"];
    
    NSString *model = self.product.model;
    
    // Display the aircract model we're connected to
    [self.connectionStatusLabel setText: model];
    
    if([model containsString:@"Inspire 1"]) {
        [Utils displayToastOnApp: @"I1"];
    } else if([model containsString:@"Phantom 3"]) {
        [Utils displayToastOnApp: @"P3"];
    }

    /* add if logic for I1 and P3
     here we would do aircraft yaw for P3 and give I1 users the option */
    
    DJIFlightController* fc = [self fetchFlightController];
    
    if (fc) {
        [fc enableVirtualStickControlModeWithCompletion:^(NSError *error) {
            if (error) {
                NSString *msg = [NSString stringWithFormat: @"%@", error.description];
                [Utils displayToastOnApp: msg];
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
    
}

-(void)doPanoLoop {
    
    NSArray *pitchGimbalYaw=@[@0,@-30,@-60];
    
    NSArray *pitchAircraftYaw=@[@0,@-30,@-60];
    
    NSArray *gimYaw30=@[@0,@30,@60,@90,@120,@150,@180,@210,@240,@270,@300,@330];
    
    NSArray *aircraftYaw30=@[@0,@45,@45,@45,@45,@45,@45,@45,@45,@45,@45,@45];
    
    NSArray *gimYaw45=@[@0,@45,@90,@135,@180,@225,@270,@315];
    
    NSArray *aircraftYaw45=@[@0,@67.5,@67.5,@67.5,@67.5,@67.5,@67.5,@67.5];
    
    NSArray *gimYaw60=@[@0,@60,@120,@180,@240,@300];

    NSArray *aircraftYaw60=@[@0,@60,@120,@180,@-120,@-60];
    
    NSMutableArray *yaw = [[NSMutableArray alloc] initWithArray:aircraftYaw60];
    
    NSMutableArray *pitch=[[NSMutableArray alloc] initWithArray:pitchAircraftYaw];
    
    droneCmdsQueue=dispatch_queue_create("com.dronepan.queue",DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Reset gimbal
        dispatch_sync(droneCmdsQueue,^{gcdResetGimbalYaw([self fetchGimbal]);});
        
        // Give gimbal time to reset
        dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
        

        // Loop through the gimbal pitches
        for (NSNumber *nPitch in pitch) {
            
            // Pitch the gimbal
            dispatch_sync(droneCmdsQueue,^{gcdSetPitch([self fetchGimbal], [nPitch floatValue]);});
            
            // Let the gimbal get into position before we yaw and take photos
            dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
        
            // Yaw loop and photo
            for (NSNumber *nYaw in yaw) {
                
                // Timer and run loop so that we can yaw to the desired location
                dispatch_sync(droneCmdsQueue,^{
                    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:[nYaw floatValue]], @"yaw", nil];
                    NSTimer* sendTimer =[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(yaw:) userInfo:data repeats:YES];
                    [[NSRunLoop currentRunLoop]addTimer:sendTimer forMode:NSDefaultRunLoopMode];
                    [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
                    [sendTimer invalidate];
                    sendTimer=nil;
                });
                
                // Delay 2 seconds so we can yaw
                dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
                
                // Take the photo
                dispatch_sync(droneCmdsQueue,^{gcdTakeASnap([self fetchCamera]);});
                
                // Delay after the photo
                dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
            }
            
        } // End pitch loop
        
        // Take the final nadir shot and then reset the gimbal back
        dispatch_sync(droneCmdsQueue,^{gcdSetPitch([self fetchGimbal], -90);});
        dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
        dispatch_sync(droneCmdsQueue,^{gcdTakeASnap([self fetchCamera]);});
        dispatch_sync(droneCmdsQueue,^{gcdDelay(2);});
        dispatch_sync(droneCmdsQueue,^{gcdResetGimbalYaw([self fetchGimbal]);});
        
        
    }); // End GCD
    
}


#pragma mark GCD functions

static void(^gcdResetGimbalYaw)(DJIGimbal*)=^(DJIGimbal *gimbal){
    [gimbal resetGimbalWithCompletion: nil];
};

static void (^gcdDelay)(unsigned int)=^(unsigned int delay){
    sleep(delay);
};


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

-(void) yaw:(NSTimer *)timer {
    
    NSDictionary *data = [timer userInfo];
    
    DJIVirtualStickFlightControlData ctrlData = {0};
    ctrlData.pitch = 0;
    ctrlData.roll = 0;
    ctrlData.verticalThrottle = 0;
    ctrlData.yaw = [[data objectForKey: @"yaw"] floatValue];
    
    DJIFlightController* fc = [self fetchFlightController];
    
    if (fc && fc.isVirtualStickControlModeAvailable) {
        [fc sendVirtualStickFlightControlData:ctrlData withCompletion:nil];
    }
}

static void (^gcdTakeASnap)(DJICamera*)=^(DJICamera *camera){
    
    [camera startShootPhoto:DJICameraShootPhotoModeSingle withCompletion:^(NSError * _Nullable error) {
        if (error) {
            [Utils displayToastOnApp: @"Error taking photo"];
        }
    }];
    
};

static void(^gcdSetPitch)(DJIGimbal*,float)=^(DJIGimbal *gimbal,float pitch){
    
    DJIGimbalAngleRotation pitchRotation, rollRotation, yawRotation = {};
    pitchRotation.enabled = YES;
    pitchRotation.angle = pitch;
    
    rollRotation.enabled = NO;
    yawRotation.enabled = NO;
    
    [gimbal rotateGimbalWithAngleMode: DJIGimbalAngleModeAbsoluteAngle pitch: pitchRotation roll:rollRotation yaw:yawRotation withCompletion:^(NSError * _Nullable error) {
        
    }];
};

#pragma mark - DJICameraDelegate
-(void)camera:(DJICamera *)camera didReceiveVideoData:(uint8_t *)videoBuffer length:(size_t)size {
    uint8_t* pBuffer = (uint8_t*)malloc(size);
    memcpy(pBuffer, videoBuffer, size);
    [[VideoPreviewer instance].dataQueue push:pBuffer length:(int)size];
}

#pragma mark Hardware helper methods
- (DJICamera*) fetchCamera {
    
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).camera;
    }
    
    return nil;
}

- (DJIFlightController*) fetchFlightController {
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    
    return nil;
}

- (DJIGimbal*) fetchGimbal {
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).gimbal;
    }
    /*else if ([[DJISDKManager product] isKindOfClass:[DJIHandheld class]]) {
        return ((DJIHandheld*)[DJISDKManager product]).gimbal;
    }*/
    
    return nil;
}


#pragma mark DJISDKManagerDelegate Method

// Called from startConnectionToProduct
- (void) sdkManagerProductDidChangeFrom:(DJIBaseProduct* _Nullable) oldProduct to:(DJIBaseProduct* _Nullable) newProduct {
    
    if (newProduct) {
        self.product = newProduct;
        
        [self.connectionStatusLabel setText: newProduct.model];
        
        __weak DJICamera* camera = [self fetchCamera];
    
        if (camera) {
            [camera setDelegate:self];
        }
        
    // Disconnected - let's update status label here
    } else {
        NSLog(@"Product disconnected");
    }
}

- (void)sdkManagerDidRegisterAppWithError:(NSError *)error {
    
    if (error) {
        NSString *msg = [NSString stringWithFormat: @"%@", error.description];
        [Utils displayToastOnApp: msg];
    } else {
    
    #if ENABLE_DEBUG_MODE
        [DJISDKManager enterDebugModeWithDebugId:@"Please type in Debug ID of the DJI Bridge app here"];
    #else
        // This will call sdkManagerProductDidChangeFrom
        [DJISDKManager startConnectionToProduct];
    #endif
        [[VideoPreviewer instance] start];
    
    }
    
    //[self showAlertViewWithTitle:@"Register App" withMessage:message];
}

@end
