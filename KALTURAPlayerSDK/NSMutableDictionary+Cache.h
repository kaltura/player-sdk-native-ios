//
//  NSMutableDictionary+Cache.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/23/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (Cache)
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * encoding;
@property (nonatomic, retain) NSString * mimeType;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSDate * lastUsed;
@property (nonatomic, retain) NSDictionary *allHeaderFields;
@property (nonatomic) NSInteger statusCode;
@end
