//
//  SKShareBrowserViewController.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/6/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPShareBrowserViewController.h"
#import "KPShareManager.h"

@interface KPShareBrowserViewController () <UIWebViewDelegate>{
    
    __weak IBOutlet UIWebView *webview;
    __weak IBOutlet UIView *loadingView;
}

@end

@implementation KPShareBrowserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:@"KPShareBrowserViewController" bundle:shareBundle()];
    if (self) {
        return self;
    }
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //_redirectURI = @"https://developers.facebook.com/tools";
    [webview loadRequest:[NSURLRequest requestWithURL:_shareURL]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)cancelPressed:(UIBarButtonItem *)sender {
    [_delegate shareBrowser:self result:KPShareResultsCancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *currentRequest = request.URL.absoluteString;
    NSLog(@"Current Request : %@", currentRequest);
    for (NSString *redirectUrl in _redirectURI) {
        if ([currentRequest hasPrefix:redirectUrl]) {
            [_delegate shareBrowser:self result:KPShareResultsSuccess];
            break;
        }
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIView animateWithDuration:0.35 animations:^{
        loadingView.alpha = 0;
    }];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [_delegate shareBrowser:self result:KPShareResultsFailed];
}
@end
