//
//  KPShareViewController.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/4/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KPShareViewController : UIViewController
@property (nonatomic, copy) NSArray *shareProvidersArr;
@property (nonatomic, copy) NSString *sharedURL;
@property (nonatomic, copy) NSString *shareIconLink;
@end
