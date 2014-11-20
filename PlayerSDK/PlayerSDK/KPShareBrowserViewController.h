//
//  SKShareBrowserViewController.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/6/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KPShareManager.h"

@class KPShareBrowserViewController;
@protocol KPShareBrowserViewControllerDelegate <NSObject>

- (void)shareBrowser:(KPShareBrowserViewController *)shareBrowser result:(KPShareResults)result;

@end

@interface KPShareBrowserViewController : UIViewController
@property (nonatomic, strong) NSURL *shareURL;
@property (nonatomic, copy) NSArray *redirectURI;
@property (nonatomic, weak) id<KPShareBrowserViewControllerDelegate> delegate;
@end
