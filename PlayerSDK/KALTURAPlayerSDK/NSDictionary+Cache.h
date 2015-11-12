//
//  NSDictionary+Cache.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/23/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Cache)
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSData * data;
@property (nonatomic, readonly) NSString * encoding;
@property (nonatomic, readonly) NSString * mimeType;
@property (nonatomic, readonly) NSDate * timestamp;
@property (nonatomic, readonly) NSString * url;
@property (nonatomic, readonly) NSDate * lastUsed;
@end
