//
//  TermsViewController.m
//  DronePan
//
//  Created by Dennis Baldwin on 8/24/15.
//  Copyright (c) 2015 Unmanned Airlines, LLC. All rights reserved.
//

#import "TermsViewController.h"

@interface TermsViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *agree;

@end

@implementation TermsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadWebView];
    

}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
}

-(void)loadWebView {
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"dronepan_terms" ofType:@"html"]];
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (IBAction)dismissTerms:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
