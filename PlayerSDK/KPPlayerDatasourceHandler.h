//
//  KPPlayerDatasource.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPViewControllerProtocols.h"

/// Key names of the video request
static NSString *KPPlayerDatasourceWidKey = @"wid";
static NSString *KPPlayerDatasourceUiConfIdKey = @"uiconf_id";
static NSString *KPPlayerDatasourceCacheStKey = @"cache_st";
static NSString *KPPlayerDatasourceEntryId = @"entry_id";
static NSString *KPPlayerDatasourcePlayerIdKey = @"playerId";
static NSString *KPPlayerDatasourceUridKey = @"urid";

@interface KPPlayerDatasourceHandler : NSObject

/** Converts datasource into video request
 *
 *  @param  id<KPViewControllerDatasource> Contains all the params for building the video request
 *  @return NSURLRequest video request
 */
+ (NSURLRequest *)videoRequest:(id<KPViewControllerDatasource>)params;
@end
