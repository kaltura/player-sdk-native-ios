//
//  SKShareBrowserViewController.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/6/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPBrowserViewController.h"
#import "DeviceParamsHandler.h"

@interface KPBrowserViewController () <UIWebViewDelegate>{
    
    __weak IBOutlet UIWebView *webview;
    __weak IBOutlet UIView *loadingView;
}

@end

@implementation KPBrowserViewController

+ (id)currentBrowser {
    NSString *nibName = isIOS(8) ? @"KPWebKitBrowserViewController" : @"KPBrowserViewController";
    return [[NSClassFromString(nibName) alloc] initWithNibName:nibName bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    NSBundle *playerBundle = [NSBundle bundleWithURL:[[NSBundle mainBundle]
                                                      URLForResource:@"KALTURAPlayerSDK"
                                                      withExtension:@"bundle"]];
    self = [super initWithNibName:nibNameOrNil bundle:playerBundle];
    if (self) {
        return self;
    }
    return nil;
}

- (void)setCompletionHandler:(KPBrowserCompletionHandler)completionHandler {
    _completionHandler = completionHandler;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [webview loadRequest:[NSURLRequest requestWithURL:_url]];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [webview loadHTMLString:@"" baseURL:nil];
    [webview stopLoading];
    webview.delegate = nil;
    [webview removeFromSuperview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)cancelPressed:(UIBarButtonItem *)sender {
    if (_completionHandler) {
        _completionHandler(KPBrowserResultSuccess, nil);
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark
#pragma mark UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *currentRequest = request.URL.absoluteString;
    for (NSString *redirectUrl in _redirectURIs) {
        if ([currentRequest hasPrefix:redirectUrl] && _completionHandler) {
            _completionHandler(KPBrowserResultSuccess, nil);
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
    if (_completionHandler) {
        _completionHandler(KPBrowserResultFailed, error);
    }
}

- (void)dealloc {
    _completionHandler = nil;
}
@end
