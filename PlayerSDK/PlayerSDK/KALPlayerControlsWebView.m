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


#import "KALPlayerControlsWebView.h"


@implementation KALPlayerControlsWebView {
    BOOL isAd;
}
@synthesize playerControlsWebViewDelegate;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        // Set delegate in order to "shouldStartLoadWithRequest" to be called
        self.delegate = self;
        
        // Set non-opaque in order to make "body{background-color:transparent}" working!
        self.opaque = NO;
        
        // Instanciate JSON parser library
        json = [ SBJSON new ];
        
    
//        NSURL *url = [[NSBundle mainBundle] URLForResource:@"www/webview-document" withExtension:@"html"];
//        [self loadRequest:[NSURLRequest requestWithURL:url]];
        
        // load our html file
//        NSString *path = [[NSBundle mainBundle] pathForResource:@"webview-document" ofType:@"html"];
//        [self loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
        
    }
    return self;
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
    
	NSString *requestString = [[request URL] absoluteString];
    
    //NSLog(@"request : %@",requestString);
    
    if ([requestString hasPrefix:@"js-frame:"]) {
        
        NSArray *components = [requestString componentsSeparatedByString:@":"];
        
        NSString *function = (NSString*)[components objectAtIndex:1];
		int callbackId = [((NSString*)[components objectAtIndex:2]) intValue];
        NSString *argsAsString = [(NSString*)[components objectAtIndex:3]
                                  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSArray *args = (NSArray*)[json objectWithString:argsAsString error:nil];
        
        [self handleCall:function callbackId:callbackId args:args];
        isAd = YES;
        
        return NO;
    } else if( isAd ){
        [[UIApplication sharedApplication] openURL: request.URL];
        return NO;
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
    
    NSString *resultArrayString = [json stringWithObject:resultArray allowScalar:YES error:nil];
    
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"NativeBridge.resultForCallback(%d,%@);",callbackId,resultArrayString]];
}

// Implements all you native function in this one, by matching 'functionName' and parsing 'args'
// Use 'callbackId' with 'returnResult' selector when you get some results to send back to javascript
- (void)handleCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args
{
    [playerControlsWebViewDelegate handleHtml5LibCall:functionName callbackId:callbackId args:args];
}

// Just one example with AlertView that show how to return asynchronous results
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (!alertCallbackId) return;
    
    NSLog(@"prompt result : %d",buttonIndex);
    
    BOOL result = buttonIndex==1?YES:NO;
    [self returnResult:alertCallbackId args:[NSNumber numberWithBool:result],nil];
}
@end