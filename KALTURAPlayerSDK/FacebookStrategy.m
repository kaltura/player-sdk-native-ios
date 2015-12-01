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
        
        if ([shareParams respondsToSelector:@selector(thumbnailLink)]) {
            NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[shareParams thumbnailLink]]];
            [controller addImage:[UIImage imageWithData:imgData]];
        }
        
        if ([shareParams respondsToSelector:@selector(shareLink)]) {
            [controller addURL:[NSURL URLWithString:[shareParams shareLink]]];
        }
        
        if ([shareParams respondsToSelector:@selector(videoName)]) {
            [controller setInitialText:[shareParams videoName]];
        }
        
        return controller;
    }
    return [self shareWithBrowser:shareParams completion:completion];
}

- (KPBrowserViewController *)shareWithBrowser:(id<KPShareParams>)params
                                   completion:(KPShareCompletionBlock)completion {
    
    KPBrowserViewController *browser = [KPBrowserViewController currentBrowser];
    browser.url = [self shareURL:params];
    browser.redirectURIs = [params redirectURLs];
    __weak UIViewController *weakBrowser = browser;
    [browser setCompletionHandler: ^(KPBrowserResult result, NSError *error) {
        [weakBrowser dismissViewControllerAnimated:YES completion:nil];
        KPShareError *shareError = nil;
        if (error) {
            shareError = [KPShareError new];
            shareError.error = error;
        }
        completion((KPShareResults)result, shareError);
    }];
//    KPWebKitBrowserViewController *browser = [KPWebKitBrowserViewController new];
//    browser.url = [self shareURL:params];
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

@end
