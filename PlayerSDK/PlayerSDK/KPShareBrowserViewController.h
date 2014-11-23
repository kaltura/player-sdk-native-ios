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

/// Call back for the Native in app browser
@protocol KPShareBrowserViewControllerDelegate <NSObject>

/** Notifies the caller what happens with the share request
 *
 *  @param  KPShareBrowserViewController The current instance of the browser
 *  @param  KPShareResults Share result type
 *
 */
- (void)shareBrowser:(KPShareBrowserViewController *)shareBrowser result:(KPShareResults)result;

@end

@interface KPShareBrowserViewController : UIViewController

/// The share url for the current network
@property (nonatomic, strong) NSURL *url;

/// Array of possible redirect URIs (notifies on finished share call)
@property (nonatomic, copy) NSArray *redirectURIs;

/// Delegate of the browser
@property (nonatomic, weak) id<KPShareBrowserViewControllerDelegate> delegate;
@end
