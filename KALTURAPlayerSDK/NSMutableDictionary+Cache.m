//
//  NSMutableDictionary+Cache.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/23/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "NSMutableDictionary+Cache.h"

@implementation NSMutableDictionary (Cache)
@dynamic path;
@dynamic data;
@dynamic encoding;
@dynamic mimeType;
@dynamic timestamp;
@dynamic url;
@dynamic lastUsed;

- (void)setPath:(NSString *)path {
    [self addValue:path forKey:@"path"];
}

- (NSString *)path {
    return self[@"path"];
}

- (void)setData:(NSData *)data {
    [self addValue:data forKey:@"data"];
}

- (NSData *)data {
    return self[@"data"];
}

- (void)setEncoding:(NSString *)encoding {
    [self addValue:encoding forKey:@"encoding"];
}

- (void)setAllHeaderFields:(NSDictionary *)allHeaderFields {
    [self addValue:allHeaderFields forKey:@"allHeaderFields"];
}

- (void)setStatusCode:(NSInteger)statusCode {
    [self addValue:@(statusCode) forKey:@"statusCode"];
}

- (NSString *)encoding {
    return self[@"encoding"];
}

- (void)setMimeType:(NSString *)mimeType {
    [self addValue:mimeType forKey:@"mimeType"];
}

- (NSString *)mimeType {
    return self[@"mimeType"];
}

- (void)setTimestamp:(NSDate *)timestamp {
    [self addValue:timestamp forKey:@"timeStamp"];
}

- (NSDate *)timestamp {
    return self[@"timeStamp"];
}

- (void)setUrl:(NSString *)url {
    [self addValue:url forKey:@"url"];
}

- (NSString *)url {
    return self[@"url"];
}

- (void)setLastUsed:(NSDate *)lastUsed {
    [self addValue:lastUsed forKey:@"lastUsed"];
}

- (NSDate *)lastUsed {
    return self[@"lastUsed"];
}

- (NSDictionary *)allHeaderFields {
    return self[@"allHeaderFields"];
}

- (NSInteger)statusCode {
    return [self[@"statusCode"] integerValue];
}

- (void)addValue:(id)value forKey:(NSString *)key {
    if (value && key) {
        self[key] = value;
    }
}

@end
