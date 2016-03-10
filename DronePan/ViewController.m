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
    NSString *msg = [NSString stringWithFormat: @"%@", self.product.model];

    /* add if logic for I1 and P3
     here we would do aircraft yaw for P3 and give I1 users the option */
    
    DJIFlightController* fc = [self fetchFlightController];
    
    if (fc) {
        fc.yawControlMode = DJIVirtualStickYawControlModeAngle;
        fc.rollPitchControlMode = DJIVirtualStickRollPitchControlModeAngle;
        fc.verticalControlMode = DJIVirtualStickVerticalControlModeVelocity;
        
        [fc enableVirtualStickControlModeWithCompletion:^(NSError *error) {
            if (error) {
                NSString *msg = [NSString stringWithFormat: @"%@", error.description];
                [self displayToast: msg];
            } else {
                [self doPanoLoop];
            }
        }];
    } else {
        // Do something or nothing here
        return;
    }
    
}

-(void)doPanoLoop {
    /*NSArray *pitchGimbalYaw=@[@0,@-30,@-60];
    
    NSArray *pitchAircraftYaw=@[@30,@0,@-30,@-60];
    
    NSArray *gimYaw30=@[@0,@30,@60,@90,@120,@150,@180,@210,@240,@270,@300,@330];
    
    NSArray *aircraftYaw30=@[@0,@45,@45,@45,@45,@45,@45,@45,@45,@45,@45,@45];
    
    NSArray *gimYaw45=@[@0,@45,@90,@135,@180,@225,@270,@315];
    
    NSArray *aircraftYaw45=@[@0,@67.5,@67.5,@67.5,@67.5,@67.5,@67.5,@67.5];
    
    NSArray *gimYaw60=@[@0,@60,@120,@180,@240,@300];*/

    NSArray *aircraftYaw60=@[@0,@60,@120,@180,@-120,@-60];
    
    NSMutableArray *yaw = [[NSMutableArray alloc] initWithArray:aircraftYaw60];
    
    droneCmdsQueue=dispatch_queue_create("com.dronepan.queue",DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Reset gimbal
        dispatch_sync(droneCmdsQueue,^{gcdResetGimbalYaw([self fetchGimbal]);});
        
        // Give gimbal time to reset
        dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
        
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
            
            // Delay 3 seconds so we can yaw
            dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
            
            // Take the photo
            dispatch_sync(droneCmdsQueue,^{gcdTakeASnap([self fetchCamera]);});
            
            // Delay after the photo
            dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
        }
        
    });
    
    //DJIGimbal* gimbal = [self fetchGimbal];
    //[gimbal resetGimbalWithCompletion: nil];
    
    
    
    /*droneCmdsQueue=dispatch_queue_create("com.dronepan.queue",DISPATCH_QUEUE_SERIAL);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        dispatch_sync(droneCmdsQueue,^{gcdResetGimbalYaw(gimbal);});
        
        dispatch_sync(droneCmdsQueue,^{gcdDelay(3);});
        
        // Loop and take photos
        for (NSNumber *nYaw in yaw) {
            
            __block float nDegreeYaw=[nYaw floatValue];
            
            dispatch_sync(droneCmdsQueue,^{gcdYawDrone(nDegreeYaw, fc);});
                
            dispatch_sync(droneCmdsQueue,^{gcdDelay(10);});
            
        }

    });*/
    
}



#pragma mark GCD functions

static void(^gcdResetGimbalYaw)(DJIGimbal*)=^(DJIGimbal *gimbal){
    [gimbal resetGimbalWithCompletion: nil];
};

static void (^gcdDelay)(unsigned int)=^(unsigned int delay){
    sleep(delay);
};

static void (^gcdYawDrone)(float,DJIFlightController*)=^(float yaw,DJIFlightController *fc){
    
    /*NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:yaw], @"yaw", nil];
    
    NSTimer* sendTimer =[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(yaw:) userInfo:data repeats:YES];
    [[NSRunLoop currentRunLoop]addTimer:sendTimer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop]runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];
    [sendTimer invalidate];
    sendTimer=nil;*/
    
    DJIVirtualStickFlightControlData ctrlData = {0};
    ctrlData.pitch = 0;
    ctrlData.roll = 0;
    ctrlData.verticalThrottle = 0;
    ctrlData.yaw = 60;
    
    if (fc && fc.isVirtualStickControlModeAvailable) {
        [fc sendVirtualStickFlightControlData:ctrlData withCompletion:nil];
    }
    
};

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
            // Need to get UTILS DISPLAYTOAST HOOKED UP
        }
    }];
    
    /*[camera startTakePhoto:CameraSingleCapture withResult:^(DJIError *error) {
        
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
    }*/
};

-(void)displayToast:(UIView *)view message:(NSString *)message{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.color = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = message;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:5];
}

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
        [self displayToast: msg];
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

#pragma mark Utils
- (void)displayToast:(NSString *)message{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo: self.view animated:YES];
    hud.color = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = message;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:5];
}

@end
