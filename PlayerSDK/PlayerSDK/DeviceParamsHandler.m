//
//  DeviceParamsHandler.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/9/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//


#import <AdSupport/AdSupport.h>
#import "DeviceParamsHandler.h"

void setUserAgent() {
    NSString* suffixUA = @"kalturaNativeCordovaPlayer";
    UIWebView* wv = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString* defaultUA = [wv stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSString* finalUA = [defaultUA stringByAppendingString:suffixUA];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:finalUA, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}


NSString *advertiserID() {
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

BOOL isDeviceOrientation(UIDeviceOrientation orientation) {
    return _deviceOrientation == orientation;
}

BOOL isStatusBarOrientation(UIInterfaceOrientation orientation) {
    return _statusBarOrientation == orientation;
}



@implementation DeviceParamsHandler
+ (BOOL)compareOrientation:(UIDeviceOrientation)compareTo listOfOrientations:(UIDeviceOrientation)list, ... {
    if (compareTo == list) {
        return YES;
    }
    BOOL isOneOf = NO;
    va_list ap;
    int i;
    va_start(ap, list);
    for (i = 0; i < list; i++) {
        isOneOf |= va_arg(ap, UIDeviceOrientation) == compareTo;
    }
    return isOneOf;
}
@end
