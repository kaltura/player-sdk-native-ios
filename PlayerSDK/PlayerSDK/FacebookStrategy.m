 //
//  FacebookStrategy.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/5/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "FacebookStrategy.h"
#import "KPShareBrowserViewController.h"

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
        
        if ([shareParams respondsToSelector:@selector(shareIconName)]) {
            [controller addImage:[UIImage imageNamed:[shareParams shareIconName]]];
        }
        
        if ([shareParams respondsToSelector:@selector(shareLink)]) {
            [controller addURL:[NSURL URLWithString:[shareParams shareLink]]];
        }
        
        return controller;
    }
    KPShareBrowserViewController *browser = [KPShareBrowserViewController new];
    browser.shareURL = [self shareURL:shareParams];
    return browser;
}

- (NSURL *)shareURL:(id<KPShareParams>)params {
    NSString *appID = @"145634995501895";
    if ([params facebookAppID]) {
        appID = [params facebookAppID];
    }
    
    NSString *caption = @"some text";
    if ([params shareDescription]) {
        caption = [params shareDescription];
    }
    
    NSString *sharedLink = @"";
    if ([params shareLink]) {
        sharedLink = [params shareLink];
    }
    
    NSString *requestString = [NSString stringWithFormat:@"https://www.facebook.com/dialog/share?app_id=%@&display=popup&caption=%@&redirect_uri=https://developers.facebook.com/tools/explorer&href=%@", appID, caption, sharedLink];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:requestString];
}
@end
