//
//  MessageStrategy.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/6/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "smsStrategy.h"
#import <MessageUI/MFMessageComposeViewController.h>

@interface SmsStrategy() <MFMessageComposeViewControllerDelegate>{
    KPShareCompletionBlock _completion;
}

@end

@implementation SmsStrategy
- (UIViewController *)share:(id<KPShareParams>)shareParams completion:(KPShareCompletionBlock)completion {
    _completion = [completion copy];
    MFMessageComposeViewController *messageController = [MFMessageComposeViewController new];
    messageController.messageComposeDelegate = self;
    [messageController setSubject:[shareParams videoName]];
    NSString *messageBody = [[shareParams videoName] stringByAppendingFormat:@"\n\n%@", [shareParams shareLink]];
    [messageController setBody:messageBody];
    return messageController;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:^{
        if (result == MessageComposeResultSent) {
            _completion(KPShareResultsSuccess, nil);
        } else if (result == MessageComposeResultCancelled) {
            _completion(KPShareResultsCancel, nil);
        } else {
            _completion(KPShareResultsFailed, nil);
        }
    }];
}

- (void)dealloc {
    
}
@end
