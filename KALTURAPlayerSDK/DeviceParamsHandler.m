//
//  DeviceParamsHandler.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/9/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//


#import "DeviceParamsHandler.h"

void setUserAgent() {
    NSString* suffixUA = @"kalturaNativeCordovaPlayer";
    UIWebView* wv = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString* defaultUA = [wv stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSString* finalUA = [defaultUA stringByAppendingString:suffixUA];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:finalUA, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
}


NSString *appVersion() {
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    return [NSString stringWithFormat:@"iOS_%@_%@", version, build];
}

BOOL isDeviceOrientation(UIDeviceOrientation orientation) {
    return _deviceOrientation == orientation;
}

BOOL isStatusBarOrientation(UIInterfaceOrientation orientation) {
    return _statusBarOrientation == orientation;
}

CGRect screenBounds() {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation) || isIOS(8)) {
        return [UIScreen mainScreen].bounds;
    }
    CGSize size = [UIScreen mainScreen].bounds.size;
    return (CGRect){CGPointZero, size.height, size.width};
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
