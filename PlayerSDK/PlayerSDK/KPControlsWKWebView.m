//
//  KPControlsWKWebview.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 4/12/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPControlsWKWebview.h"

@interface KPControlsWKWebview() <WKNavigationDelegate>

@end

@implementation KPControlsWKWebview
@synthesize entryId= _entryId, controlsDelegate, controlsFrame = _controlsFrame;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.navigationDelegate = self;
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
    [[KArchiver shared] contentOfURL:request.URL.absoluteString
                          completion:^(NSData *content, NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  NSString *html = [[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding];
                                  html = [html stringByReplacingOccurrencesOfString:@"</head>"
                                                                         withString:@"</head><meta name=\"viewport\" content=\"initial-scale=1.0\" />"];
                                  [self loadHTMLString:html
                                               baseURL:request.URL];
                              });
                          }];
}

- (void)setEntryId:(NSString *)entryId {
    if (![self.entryId isEqualToString:entryId]) {
        _entryId = entryId;
        NSString *notificationName = [NSString stringWithFormat:@"'{\"entryId\":\"%@\"}'", entryId];
        [self sendNotification:@"changeMedia" withName:notificationName];
    }
}

- (void)fetchvideoHolderHeight:(void (^)(CGFloat))fetcher {
        [self evaluateJavaScript:@"NativeBridge.videoPlayer.getVideoHolderHeight()" completionHandler:^(id result, NSError *error) {
            if (error) {
                KPLogError(@"JS Error %@", error.description);
            } else if (result) {
//                _videoHolderHeight = [result floatValue];
                fetcher([result floatValue]);
            }
        }];
}

- (void)removeControls {
    self.navigationDelegate = nil;
    self.controlsDelegate = nil;
    self.entryId = nil;
    [self removeFromSuperview];
}

- (void)setControlsFrame:(CGRect)controlsFrame {
    self.frame = controlsFrame;
}

- (CGRect)controlsFrame {
    return self.frame;
}

- (void)addEventListener:(NSString *)event {
    [self evaluateJavaScript:event.addJSListener completionHandler:nil];
}

- (void)removeEventListener:(NSString *)event {
    [self evaluateJavaScript:event.removeJSListener completionHandler:nil];
}

- (void)evaluate:(NSString *)expression evaluateID:(NSString *)evaluateID {
    [self evaluateJavaScript:[expression evaluateWithID:evaluateID] completionHandler:nil];
}

- (void)sendNotification:(NSString *)notification withName:(NSString *)notificationName {
    [self evaluateJavaScript:[notificationName sendNotificationWithBody:notification] completionHandler:nil];
}

- (void)setKDPAttribute:(NSString *)pluginName propertyName:(NSString *)propertyName value:(NSString *)value {
    [self evaluateJavaScript:[pluginName setKDPAttribute:propertyName value:value] completionHandler:nil];
}

- (void)triggerEvent:(NSString *)event withValue:(NSString *)value {
    [self evaluateJavaScript:[event triggerEvent:value] completionHandler:nil];
}

- (void)triggerEvent:(NSString *)event withJSON:(NSString *)json {
    [self evaluateJavaScript:[event triggerJSON:json] completionHandler:nil];
}


- (void)updateLayout {
    NSString *updateLayoutJS = @"document.getElementById( this.id ).doUpdateLayout();";
    [self evaluateJavaScript:updateLayoutJS completionHandler:nil];
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

@end
