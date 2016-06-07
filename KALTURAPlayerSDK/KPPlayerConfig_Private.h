//
//  KPPlayerConfig_Private.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 22/03/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPPlayerConfig.h"


@interface KPPlayerConfig ()
-(BOOL)waitForPlayerRootUrl;
@property (nonatomic) NSTimeInterval startFrom;
@property (nonatomic, copy) NSString* resolvedPlayerURL;
@end