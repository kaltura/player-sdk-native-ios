//
//  KPControlsWKWebview.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 4/12/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPControlsWKWebview.h"

@interface KPControlsWKWebview() <WKNavigationDelegate, WKUIDelegate> {
    WKWebViewConfiguration *configuration;
}

@end

@implementation KPControlsWKWebview
@synthesize entryId= _entryId, controlsDelegate, controlsFrame = _controlsFrame, shouldUpdateLayout;

- (instancetype)initWithFrame:(CGRect)frame {
    // Javascript that disables pinch-to-zoom by inserting the HTML viewport meta tag into <head>
    NSString *source = @"var meta = document.createElement('meta'); \
    meta.name = 'viewport'; \
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; \
    var head = document.getElementsByTagName('head')[0];\
    head.appendChild(meta);";
    WKUserScript *script = [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    
    // Create the user content controller and add the script to it
    WKUserContentController *userContentController = [WKUserContentController new];
    [userContentController addUserScript:script];
    
    // Create the configuration with the user content controller
    configuration = [WKWebViewConfiguration new];
    configuration.userContentController = userContentController;
    
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        self.navigationDelegate = self;
        self.UIDelegate = self;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.opaque = NO;
        self.scrollView.scrollEnabled = NO;
        self.scrollView.bounces = NO;
        self.scrollView.bouncesZoom = NO;
        self.backgroundColor = [UIColor clearColor];
        return self;
    }
    return nil;
}

- (void)loadRequest:(NSURLRequest *)request {
    if (self.isLoading) {
        [self stopLoading];
    }
    [super loadRequest:request];
}


- (void)setEntryId:(NSString *)entryId {
    if (![_entryId isEqualToString:entryId]) {
        _entryId = entryId;
        NSString *entry = [NSString stringWithFormat:@"'{\"entryId\":\"%@\"}'", entryId];
        [self sendNotification:@"changeMedia" withParams:entry];
    }
}

- (void)fetchvideoHolderHeight:(void (^)(CGFloat))fetcher {
        [self evaluateJavaScript:@"NativeBridge.videoPlayer.getVideoHolderHeight()" completionHandler:^(id result, NSError *error) {
            if (error) {
                KPLogError(@"JS Error %@", error.description);
            } else if (result) {
                fetcher([result floatValue]);
            }
        }];
}

- (CGRect)controlsFrame {
    return self.frame;
}

- (void)removeControls {
    [self stopLoading];
    self.navigationDelegate = nil;
    self.controlsDelegate = nil;
    self.entryId = nil;
    [self removeFromSuperview];
}

- (void)setControlsFrame:(CGRect)controlsFrame {
    self.frame = controlsFrame;
}

- (void)addEventListener:(NSString *)event {
    [self evaluateJavaScript:event.addJSListener completionHandler:nil];
}

- (void)removeEventListener:(NSString *)event {
    [self evaluateJavaScript:event.removeJSListener completionHandler:nil];
}

- (void)evaluate:(NSString *)expression evaluateID:(NSString *)evaluateID {
    [self evaluateJavaScript:asyncEvaluate(expression, evaluateID) completionHandler:nil];
}

- (void)sendNotification:(NSString *)notification withParams:(NSString *)params {
    [self evaluateJavaScript:sendNotification(notification, params) completionHandler:nil];
}

- (void)setKDPAttribute:(NSString *)pluginName propertyName:(NSString *)propertyName value:(NSString *)value {
    [self evaluateJavaScript:setKDPAttribute(pluginName, propertyName, value) completionHandler:nil];
}

- (void)triggerEvent:(NSString *)event withValue:(NSString *)value {
    [self evaluateJavaScript:triggerEvent(event, value) completionHandler:nil];
}

- (void)triggerEvent:(NSString *)event withJSON:(NSString *)json {
    [self evaluateJavaScript:triggerEventWithJSON(event, json) completionHandler:nil];
}


- (void)updateLayout {
    [self sendNotification:@"doUpdateLayout" withParams:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSString *requestString = navigationAction.request.URL.absoluteString;
    KPLogDebug(@"requestString %@", requestString);
    if (requestString.isJSFrame) {
        FunctionComponents functionComponents = requestString.extractFunction;
        if (functionComponents.error) {
            KPLogError(@"JSON parsing error: %@", functionComponents.error);
        } else {
            [self.controlsDelegate handleHtml5LibCall:functionComponents.name
                                           callbackId:functionComponents.callBackID
                                                 args:functionComponents.args];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
    } else if( !requestString.isFrameURL ) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        NSLog(@"HTTP:: %@", requestString);
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    KPLogError(@"Error: %@", [error localizedDescription]);
    [self handleError:error];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    KPLogError(@"Error: %@", [error localizedDescription]);
    [self handleError:error];

}

- (void)handleError:(NSError *)error {
    NSString *errPrefix = @"WebViewError:";
    
    NSString *localizedDescription = !error.localizedDescription ? @"" : error.localizedDescription;
    NSString *localizedFailureReason = !error.localizedFailureReason ? @"" : error.localizedFailureReason;
    
    NSDictionary *dict = @{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@", localizedDescription],
                           NSLocalizedFailureReasonErrorKey: localizedFailureReason};
    NSError *err = [NSError errorWithDomain:error.domain code:error.code userInfo:dict];
    
    if ([self.controlsDelegate respondsToSelector:@selector(handleKPControlsError:)]) {
        [self.controlsDelegate handleKPControlsError:err];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
}

- (void)reset {
    if (self.isLoading) {
        [self stopLoading];
    }
    
    [self loadRequest:[NSURLRequest requestWithURL:
                       [NSURL URLWithString:@"about:blank"]]];
}

- (void)dealloc {
    [configuration.userContentController removeAllUserScripts];
    configuration = nil;
}

@end
