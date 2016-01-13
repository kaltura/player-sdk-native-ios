//
//  KPControlsUIWebview.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 4/12/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPControlsUIWebview.h"


@interface KPControlsUIWebview() <UIWebViewDelegate>

@end

@implementation KPControlsUIWebview
@synthesize entryId = _entryId, controlsDelegate, controlsFrame = _controlsFrame, shouldUpdateLayout;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Set delegate in order to "shouldStartLoadWithRequest" to be called
        self.delegate = self;
        
        // Set non-opaque in order to make "body{background-color:transparent}" working!
        self.opaque = NO;
        self.scrollView.scrollEnabled = NO;
        self.scrollView.bounces = NO;
        self.scrollView.bouncesZoom = NO;
        self.backgroundColor = [UIColor clearColor];
        
        return self;
    }
    return nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!UIEdgeInsetsEqualToEdgeInsets([super scrollView].contentInset, UIEdgeInsetsZero)) {
        [[super scrollView] setContentInset:UIEdgeInsetsZero];
    }
}


- (void)setEntryId:(NSString *)entryId {
    if (![_entryId isEqualToString:entryId]) {
        _entryId = entryId;
        NSString *entry = [NSString stringWithFormat:@"'{\"entryId\":\"%@\"}'", entryId];
        [self sendNotification:@"changeMedia" withParams:entry];
    }
}

- (void)fetchvideoHolderHeight:(void (^)(CGFloat))fetcher {
    fetcher([[self stringByEvaluatingJavaScriptFromString:@"NativeBridge.videoPlayer.getVideoHolderHeight()"] floatValue]);
}


- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
}

- (CGRect)controlsFrame {
    return self.frame;
}

- (void)removeControls {
    self.delegate = nil;
    self.controlsDelegate = nil;
    self.entryId = nil;
    [self removeFromSuperview];
}

- (void)addEventListener:(NSString *)event {
    [self stringByEvaluatingJavaScriptFromString:event.addJSListener];
}

- (void)removeEventListener:(NSString *)event {
    [self stringByEvaluatingJavaScriptFromString:event.removeJSListener];
}

- (void)evaluate:(NSString *)expression evaluateID:(NSString *)evaluateID {
    [self stringByEvaluatingJavaScriptFromString:asyncEvaluate(expression, evaluateID)];
}

- (void)sendNotification:(NSString *)notification withParams:(NSString *)params {
    [self stringByEvaluatingJavaScriptFromString:sendNotification(notification, params)];
}

- (void)setKDPAttribute:(NSString *)pluginName propertyName:(NSString *)propertyName value:(NSString *)value {
    [self stringByEvaluatingJavaScriptFromString:setKDPAttribute(pluginName, propertyName, value)];
}

- (void)triggerEvent:(NSString *)event withValue:(NSString *)value {
    [self stringByEvaluatingJavaScriptFromString:triggerEvent(event, value)];
}

- (void)triggerEvent:(NSString *)event withJSON:(NSString *)json {
    [self stringByEvaluatingJavaScriptFromString:triggerEventWithJSON(event, json)];
}

- (void)showChromecastComponent:(BOOL)show {
    [self stringByEvaluatingJavaScriptFromString:showChromecastComponent(show)];
}

- (void)updateLayout {
    [self sendNotification:@"doUpdateLayout" withParams:nil];
}

#pragma mark UIWebviewDelegate
// This selector is called when something is loaded in our webview
// By something I don't mean anything but just "some" :
//  - main html document
//  - sub iframes document
//
// But all images, xmlhttprequest, css, ... files/requests doesn't generate such events :/
- (BOOL)webView:(UIWebView *)webView2
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    
    NSString *requestString = request.URL.absoluteString;
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
        return NO;
    } else if( !requestString.isFrameURL ) {
        [[UIApplication sharedApplication] openURL: request.URL];
        return NO;
    } else {
        NSLog(@"HTTP:: %@", requestString);
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

@end
