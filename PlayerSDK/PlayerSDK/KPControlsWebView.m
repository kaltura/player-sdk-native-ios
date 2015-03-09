/* ***** BEGIN LICENSE BLOCK *****
 # Copyright 2010 Alexandre Poirot
 #
 # Contributor(s):
 #   Alexandre poirot <poirot.alex@gmail.com>
 #
 #
 # This library is free software; you can redistribute it and/or
 # modify it under the terms of the GNU Lesser General Public
 # License as published by the Free Software Foundation; either
 # version 2.1 of the License, or (at your option) any later version.
 #
 # This library is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 # Lesser General Public License for more details.
 #
 # You should have received a copy of the GNU Lesser General Public
 # License along with this library.  If not, see <http://www.gnu.org/licenses/>.
 #
 # ***** END LICENSE BLOCK *****/

// Copyright (c) 2013 Kaltura, Inc. All rights reserved.
// License: http://corp.kaltura.com/terms-of-use
//


#import "KPControlsWebView.h"
#import "NSString+Utilities.h"
#import "KPLog.h"
#import "KArchiver.h"


@implementation KPControlsWebView

@synthesize playerControlsWebViewDelegate;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        // Set delegate in order to "shouldStartLoadWithRequest" to be called
        self.delegate = self;
        
        // Set non-opaque in order to make "body{background-color:transparent}" working!
        self.opaque = NO;
//        NSURL *url = [[NSBundle mainBundle] URLForResource:@"www/webview-document" withExtension:@"html"];
//        [self loadRequest:[NSURLRequest requestWithURL:url]];
        
        // load our html file
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"webview-document" ofType:@"html"];
//        [self loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
        
    }
    return self;
}

- (void)loadRequest:(NSURLRequest *)request {
    [[KArchiver shared] contentOfURL:request.URL.absoluteString
                          completion:^(NSData *content, NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [self loadData:content
                                        MIMEType:@"text/html"
                                textEncodingName:@"UTF-8"
                                         baseURL:request.URL];
                              });
                          }];
}

- (void)setEntryId:(NSString *)entryId {
    if (![_entryId isEqualToString:entryId]) {
        _entryId = entryId;
        NSString *notificationName = [NSString stringWithFormat:@"'{\"entryId\":\"%@\"}'", entryId];
        [self sendNotification:@"changeMedia" withName:notificationName];
    }
}

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
            [playerControlsWebViewDelegate handleHtml5LibCall:functionComponents.name
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


// Call this function when you have results to send back to javascript callbacks
// callbackId : int comes from handleCall function
// args: list of objects to send to the javascript callback
- (void)returnResult:(int)callbackId args:(id)arg, ...;
{
    va_list argsList;
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    
    if(arg != nil){
        [resultArray addObject:arg];
        va_start(argsList, arg);
        while((arg = va_arg(argsList, id)) != nil)
            [resultArray addObject:arg];
        va_end(argsList);
    }
    
    NSError* error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:resultArray options:kNilOptions error:&error];
    if (error) {
        KPLogError(@"JSON writing error: %@", error);
    } else {
        NSString *resultArrayString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"NativeBridge.resultForCallback(%d,%@);",callbackId,resultArrayString]];
    }
}


- (void)addEventListener:(NSString *)event {
    [self stringByEvaluatingJavaScriptFromString:event.addJSListener];
}

- (void)removeEventListener:(NSString *)event {
    [self stringByEvaluatingJavaScriptFromString:event.removeJSListener];
}

- (void)evaluate:(NSString *)expression evaluateID:(NSString *)evaluateID {
    [self stringByEvaluatingJavaScriptFromString:[expression evaluateWithID:evaluateID]];
}

- (void)sendNotification:(NSString *)notification withName:(NSString *)notificationName {
    [self stringByEvaluatingJavaScriptFromString:[notificationName sendNotificationWithBody:notification]];
}

- (void)setKDPAttribute:(NSString *)pluginName propertyName:(NSString *)propertyName value:(NSString *)value {
    [self stringByEvaluatingJavaScriptFromString:[pluginName setKDPAttribute:propertyName value:value]];
}

- (void)triggerEvent:(NSString *)event withValue:(NSString *)value {
    [self stringByEvaluatingJavaScriptFromString:[event triggerEvent:value]];
}

- (void)triggerEvent:(NSString *)event withJSON:(NSString *)json {
    [self stringByEvaluatingJavaScriptFromString:[event triggerJSON:json]];
}

- (CGFloat)videoHolderHeight {
    return [[self stringByEvaluatingJavaScriptFromString:@"NativeBridge.videoPlayer.getVideoHolderHeight()"] floatValue];
}

- (void)updateLayout {
    NSString *updateLayoutJS = @"document.getElementById( this.id ).doUpdateLayout();";
    [self stringByEvaluatingJavaScriptFromString:updateLayoutJS];
}

// Just one example with AlertView that show how to return asynchronous results
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (!alertCallbackId) return;
    
    KPLogInfo(@"prompt result : %ld", (long)buttonIndex);
    
    BOOL result = buttonIndex==1?YES:NO;
    [self returnResult:alertCallbackId args:[NSNumber numberWithBool:result],nil];
}

@end