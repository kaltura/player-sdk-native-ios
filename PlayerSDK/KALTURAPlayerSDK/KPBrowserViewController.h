//
//  SKShareBrowserViewController.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/6/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, KPBrowserResult){
    KPBrowserResultSuccess,
    KPBrowserResultFailed,
    KPBrowserResultCancel
};

typedef void (^KPBrowserCompletionHandler)(KPBrowserResult result, NSError *error);

@interface KPBrowserViewController : UIViewController {
    KPBrowserCompletionHandler _completionHandler;
}

/** Creates a browser according to the operating system
 *
 *  @return instancetype UIWebView browser for iOS7 and WKWebView for iOS8+
 */
+ (instancetype)currentBrowser;

/// The share url for the current network
@property (nonatomic, copy) NSURL *url;

/// Array of possible redirect URIs (notifies on finished share call)
@property (nonatomic, copy) NSArray *redirectURIs;

- (void)setCompletionHandler:(KPBrowserCompletionHandler)completionHandler;

@end
