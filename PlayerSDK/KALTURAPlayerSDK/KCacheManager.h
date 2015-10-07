//
//  KCacheManager.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/23/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CacheManager [KCacheManager shared]

@interface KCacheManager : NSObject
+ (KCacheManager *)shared;

@property (nonatomic) float cacheSize;
@property (nonatomic, copy) NSString *host;

@property (strong, nonatomic, readonly) NSDictionary *withDomain;
@property (strong, nonatomic, readonly) NSDictionary *subStrings;
@end


@interface NSString(CoreData)
@property (nonatomic, readonly) NSDictionary *cachedResponse;
@end

@interface CachedURLParams: NSObject
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSURLResponse *response;

- (void)storeCacheResponse;
@end