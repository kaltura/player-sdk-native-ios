//
//  KPDataBaseManager.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/3/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CachedURLResponse.h"

#define dataBaseMgr [KPDataBaseManager shared]

@interface KPDataBaseManager : NSObject
+ (KPDataBaseManager *)shared;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy) NSString *host;
@property (nonatomic) float cacheSize;
@end


@interface NSString(CoreData)
@property (nonatomic, readonly) CachedURLResponse *cachedResponse;
@end

@interface CachedURLParams: NSObject
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSURLResponse *response;

- (void)storeCacheResponse;
@end

