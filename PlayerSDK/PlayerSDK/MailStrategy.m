//
//  MailStrategy.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/6/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "MailStrategy.h"


@implementation MailStrategy

- (UIViewController *)share:(id<KPShareParams>)shareParams
                 completion:(KPShareCompletionBlock)completion {
    _completion = [completion copy];
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    mailController.mailComposeDelegate = self;
    [mailController setSubject:[shareParams videoName]];
    NSString *mailBody = [shareParams shareLink];
    [mailController setMessageBody:mailBody isHTML:NO];
    return mailController;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    if (error) {
        KPShareError *err = [KPShareError new];
        err.error = error;
        _completion(KPShareResultsFailed, err);
    } else if (result == MFMailComposeResultSent) {
        _completion(KPShareResultsSuccess, nil);
    } else if (result == MFMailComposeResultCancelled) {
        _completion(KPShareResultsCancel, nil);
    }
}



@end
