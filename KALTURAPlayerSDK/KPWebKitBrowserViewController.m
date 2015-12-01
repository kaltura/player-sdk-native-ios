//
//  KPWebKitBroeserViewController.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/27/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPWebKitBrowserViewController.h"
#import <WebKit/WebKit.h>

@interface KPWebKitBrowserViewController () <WKNavigationDelegate>{
    WKWebView *webview;
    __weak IBOutlet UIView *webviewHolder;
    __weak IBOutlet UIToolbar *toolbar;
    __weak IBOutlet UIProgressView *progressBar;
    NSInteger *contentLength;
}

- (IBAction)dismissPressed:(UIBarButtonItem *)sender;
@end

@implementation KPWebKitBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    webview = [[WKWebView alloc] initWithFrame:webviewHolder.bounds];
    webview.navigationDelegate = self;
    [webviewHolder addSubview:webview];
    [webview loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissPressed:(UIBarButtonItem *)sender {
    if (_completionHandler) {
        _completionHandler(KPBrowserResultSuccess, nil);
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)restetProgressBar {
    progressBar.progress = 0;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    [progressBar setProgress:webView.estimatedProgress animated:YES];
    NSString *currentRequest = navigationAction.request.URL.absoluteString;
    for (NSString *redirectUrl in self.redirectURIs) {
        if ([currentRequest hasPrefix:redirectUrl] && _completionHandler) {
            _completionHandler(KPBrowserResultSuccess, nil);
            break;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [progressBar setProgress:1.0 animated:NO];
    [self performSelector:@selector(restetProgressBar) withObject:nil afterDelay:0.5];
}


- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (_completionHandler) {
        _completionHandler(KPBrowserResultFailed, error);
    }
}


- (void)orientationChanged {
    webview.frame = webviewHolder.bounds;
}
@end
