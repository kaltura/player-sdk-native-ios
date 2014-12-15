//
//  DeviceParamsHandler.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/9/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <UIKit/UIKit.h>
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

@implementation DeviceParamsHandler

@end
