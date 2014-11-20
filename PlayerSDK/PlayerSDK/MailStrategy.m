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
    [mailController setSubject:[shareParams shareTitle]];
    NSString *mailBody = [shareParams shareLink];
    [mailController setMessageBody:mailBody isHTML:NO];
//    if ([shareParams shareIconName] && [UIImage imageNamed:[shareParams shareIconName]]) {
//        NSData *imgData = UIImageJPEGRepresentation([UIImage imageNamed:[shareParams shareIconName]], 1);
//        [mailController addAttachmentData:imgData
//                                 mimeType:@"image/jpeg"
//                                 fileName:@"publicity.png"];
//    }
//    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[shareParams shareLink]]];
//    [mailController addAttachmentData:data mimeType:@"video/m4v" fileName:@"PlayVideo"];
    return mailController;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
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
