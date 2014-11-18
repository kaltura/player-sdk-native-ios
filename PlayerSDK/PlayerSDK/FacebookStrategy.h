//
//  FacebookStrategy.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/5/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPShareManager.h"
#import "KPShareBrowserViewController.h"
#import <Social/Social.h>

@interface FacebookStrategy : NSObject <KPShareStratrgy>
@property (nonatomic, copy, readonly) NSString *composeType;

- (NSURL *)shareURL:(id<KPShareParams>)params;
@end
