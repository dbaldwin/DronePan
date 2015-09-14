//
//  DroneSelectionViewController.h
//  DronePan
//
//  Created by Dennis Baldwin on 9/7/15.
//  Copyright (c) 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DroneSelectionViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *i1Button;

@property (weak, nonatomic) IBOutlet UIButton *p3Button;

- (IBAction)p3Selected:(id)sender;

- (IBAction)i1Selected:(id)sender;
@end
