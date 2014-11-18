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
    KPShareBrowserViewController *browser = [KPShareBrowserViewController new];
    browser.shareURL = [self shareURL:shareParams];
    NSArray *redirectURIs = [[shareParams redirectURL] componentsSeparatedByString:@","];
    browser.redirectURI = redirectURIs.count ? redirectURIs : @[[shareParams redirectURL]];
    return browser;
}
@end
