 //
//  FacebookStrategy.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/5/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "FacebookStrategy.h"


@implementation FacebookStrategy

- (NSString *)composeType {
    return SLServiceTypeFacebook;
}

- (UIViewController *)share:(id<KPShareParams>)shareParams completion:(KPShareCompletionBlock)completion {
    if ([SLComposeViewController isAvailableForServiceType:self.composeType]) {
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:self.composeType];
        [controller setCompletionHandler:^(SLComposeViewControllerResult result){
            switch (result) {
                case SLComposeViewControllerResultCancelled:
                    completion(KPShareResultsCancel, nil);
                    break;
                case SLComposeViewControllerResultDone:
                    completion(KPShareResultsSuccess, nil);
                    break;
                    
                default:
                    break;
            }
        }];
        if ([shareParams respondsToSelector:@selector(shareTitle)]) {
            [controller setInitialText:shareParams.shareTitle];
        }
        
        if ([shareParams respondsToSelector:@selector(shareIconLink)]) {
            NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[shareParams shareIconLink]]];
            [controller addImage:[UIImage imageWithData:imgData]];
        }
        
        if ([shareParams respondsToSelector:@selector(shareLink)]) {
            [controller addURL:[NSURL URLWithString:[shareParams shareLink]]];
        }
        
        return controller;
    }
    KPShareBrowserViewController *browser = [KPShareBrowserViewController new];
    browser.shareURL = [self shareURL:shareParams];
    NSArray *redirectURIs = [[shareParams redirectURL] componentsSeparatedByString:@","];
    browser.redirectURI = redirectURIs.count ? redirectURIs : @[[shareParams redirectURL]];
    return browser;
}

- (NSURL *)shareURL:(id<KPShareParams>)params {
    NSString *sharedLink = @"";
    if ([params shareLink]) {
        sharedLink = [params shareLink];
    }
    NSString *requestString = [[params rootURL] stringByAppendingString:sharedLink];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:requestString];
}
@end
