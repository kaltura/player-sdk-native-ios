//
//  MailStrategy.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/6/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "KPShareManager.h"


@interface MailStrategy : NSObject <KPShareStratrgy, MFMailComposeViewControllerDelegate> {
    KPShareCompletionBlock _completion;
}


@end
