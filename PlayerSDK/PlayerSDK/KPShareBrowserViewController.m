//
//  SKShareBrowserViewController.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/6/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPShareBrowserViewController.h"

@interface KPShareBrowserViewController () <UIWebViewDelegate>{
    UIWebView *webview;
    UINavigationBar *navBar;
    UIActivityIndicatorView *spinner;
}

@end

@implementation KPShareBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //_redirectURI = @"https://developers.facebook.com/tools";
    [self initializeToolBar];
    [self initializeWebView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)initializeWebView {
    webview = [[UIWebView alloc] initWithFrame:(CGRect){0, 0, self.view.frame.size.width, self.view.frame.size.height - 44}];
    webview.delegate = self;
    webview.backgroundColor = [UIColor grayColor];
    [webview loadRequest:[NSURLRequest requestWithURL:_shareURL]];
    [self.view addSubview:webview];
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    //spinner.center = webview.center;
    [self.view addSubview:spinner];
}

- (void)initializeToolBar {
    UIToolbar* toolbar = [[UIToolbar alloc] init];
    toolbar.frame = CGRectMake(0, self.view.frame.size.height - 44, self.view.frame.size.width, 44);
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                                 target:self
                                                                                 action:@selector(cancelPressed:)];
    [toolbar setItems:@[shareButton]];
    [self.view addSubview:toolbar];
}

- (void)cancelPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *currentRequest = request.URL.absoluteString;
    NSLog(@"Current Request : %@", currentRequest);
    for (NSString *redirectUrl in _redirectURI) {
        if ([currentRequest hasPrefix:redirectUrl]) {
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
    }
    return YES;
}

//- (void)webViewDidFinishLoad:(UIWebView *)webView {
//    if ([webview.request.URL.absoluteString hasPrefix:@"https://www.facebook.com/dialog/feed"]) {
//        [UIView animateWithDuration:0.35
//                         animations:^{
//                             spinner.alpha = 0;
//                         }];
//    }
//}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}
@end
