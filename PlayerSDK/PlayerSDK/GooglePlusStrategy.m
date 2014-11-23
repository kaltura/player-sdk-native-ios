//
//  GooglePlusStrategy.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/18/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "GooglePlusStrategy.h"

@implementation GooglePlusStrategy
- (UIViewController *)share:(id<KPShareParams>)shareParams completion:(KPShareCompletionBlock)completion {
    _completion = [completion copy];
    KPShareBrowserViewController *browser = [KPShareBrowserViewController new];
    browser.url = [self shareURL:shareParams];
    browser.delegate = self;
    browser.redirectURIs = [shareParams redirectURLs];
    return browser;
}
@end
