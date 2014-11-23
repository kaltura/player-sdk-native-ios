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
        __weak UIViewController *weakController = controller;
        [controller setCompletionHandler:^(SLComposeViewControllerResult result){
            [weakController dismissViewControllerAnimated:YES completion:nil];
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
        
        if ([shareParams respondsToSelector:@selector(shareIconLink)]) {
            NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[shareParams thumbnailLink]]];
            [controller addImage:[UIImage imageWithData:imgData]];
        }
        
        if ([shareParams respondsToSelector:@selector(shareLink)]) {
            [controller addURL:[NSURL URLWithString:[shareParams shareLink]]];
        }
        
        if ([shareParams respondsToSelector:@selector(shareTitle)]) {
            [controller setInitialText:[shareParams videoName]];
        }
        
        return controller;
    }
    _completion = [completion copy];
    KPShareBrowserViewController *browser = [KPShareBrowserViewController new];
    browser.delegate = self;
    browser.url = [self shareURL:shareParams];
    browser.redirectURIs = [shareParams redirectURLs];
    return browser;
}

- (NSURL *)shareURL:(id<KPShareParams>)params {
    NSString *sharedLink = @"";
    if ([params shareLink]) {
        sharedLink = [params shareLink];
    }
    NSString *requestString = [[params networkURL] stringByAppendingString:sharedLink];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:requestString];
}

#pragma mark KPShareBrowserViewControllerDelegate
- (void)shareBrowser:(KPShareBrowserViewController *)shareBrowser result:(KPShareResults)result {
    [shareBrowser dismissViewControllerAnimated:YES completion:nil];
    if (_completion) {
        _completion(result, nil);
    }
}
@end
