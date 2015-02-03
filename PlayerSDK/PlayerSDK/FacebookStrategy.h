//
//  FacebookStrategy.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/5/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPShareManager.h"
#import "KPBrowserViewController.h"
#import <Social/Social.h>

@interface FacebookStrategy : NSObject <KPShareStratrgy>

/// SLServiceType for the Twitter and the Facebook networks
@property (nonatomic, copy, readonly) NSString *composeType;


/** Generates Share API call according to the user selection
 *
 *  @param id<KPShareParams> An NSDictionary extended class, which gets all the share params from the player
 *
 *  @return NSURL The API request which has been generated.
 */
- (NSURL *)shareURL:(id<KPShareParams>)params;

- (KPBrowserViewController *)shareWithBrowser:(id<KPShareParams>)params
                                   completion:(KPShareCompletionBlock)completion;
@end
