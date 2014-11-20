//
//  MessageStrategy.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/6/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "MessageStrategy.h"
#import <MessageUI/MFMessageComposeViewController.h>

@interface MessageStrategy() <MFMessageComposeViewControllerDelegate>{
    KPShareCompletionBlock _completion;
}

@end

@implementation MessageStrategy
- (UIViewController *)share:(id<KPShareParams>)shareParams completion:(KPShareCompletionBlock)completion {
    _completion = [completion copy];
    MFMessageComposeViewController *messageController = [MFMessageComposeViewController new];
    messageController.messageComposeDelegate = self;
    [messageController setSubject:[shareParams shareTitle]];
    NSString *messageBody = [shareParams shareLink];
    [messageController setBody:messageBody];
//    if ([shareParams shareIconName] && [UIImage imageNamed:[shareParams shareIconName]]) {
//        NSData *imgData = UIImageJPEGRepresentation([UIImage imageNamed:[shareParams shareIconName]], 1);
//        [messageController addAttachmentData:imgData
//                              typeIdentifier:@"public.data"
//                                    filename:@"publicity_image.png"];
//    }
    return messageController;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {
    if (result == MessageComposeResultSent) {
        _completion(KPShareResultsSuccess, nil);
    } else if (result == MessageComposeResultCancelled) {
        _completion(KPShareResultsCancel, nil);
    } else {
        _completion(KPShareResultsFailed, nil);
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}
@end
