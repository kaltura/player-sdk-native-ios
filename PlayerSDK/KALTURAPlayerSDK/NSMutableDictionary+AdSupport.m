//
//  NSMutableDictionary+AdSupport.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 1/19/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "NSMutableDictionary+AdSupport.h"
#import "KPLog.h"

static NSString *IsLinearKey = @"isLinear";
static NSString *AdIDKey = @"adID";
static NSString *AdSystemKey = @"adSystem";
static NSString *AdPositionKey = @"adPosition";

static NSString *ContextKey = @"context";
static NSString *DurationKey = @"duration";
static NSString *TimeKey = @"time";
static NSString *RemainTimeKey = @"remain";







@implementation NSMutableDictionary (AdSupport)
- (void)setIsLinear:(BOOL)isLinear {
    self[IsLinearKey] = @(isLinear);
}

- (BOOL)isLinear {
    return [self[IsLinearKey] boolValue];
}

- (void)setAdID:(NSString *)adID {
    self[AdIDKey] = adID ? adID : @"null";
}

- (NSString *)adID {
    return self[AdIDKey];
}

- (void)setAdSystem:(NSString *)adSystem {
    self[AdSystemKey] = @"GDFP";
}

- (NSString *)adSystem {
    return self[AdSystemKey];
}

- (void)setAdPosition:(int)adPosition {
    self[AdPositionKey] = @(adPosition);
}

- (int)adPosition {
    return [self[AdPositionKey] intValue];
}

- (void)setContext:(NSString *)context {
    self[ContextKey] = context ? context : @"null";
}

- (NSString *)context {
    return self[ContextKey];
}

- (void)setDuration:(NSTimeInterval)duration {
    self[DurationKey] = @(duration);
}

- (NSTimeInterval)duration {
    return [self[DurationKey] floatValue];
}

- (void)setTime:(NSTimeInterval)time {
    self[TimeKey] = @(time);
}

- (NSTimeInterval)time {
    return [self[TimeKey] floatValue];
}

- (void)setRemain:(NSTimeInterval)remain {
    self[RemainTimeKey] = @(remain);
}

- (NSTimeInterval)remain {
    return [self[RemainTimeKey] floatValue];
}

- (NSString *)toJSON {
    NSError *error = nil;
    NSData *toJson = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
    if (error) {
        KPLogError(@"%@", error);
        return nil;
    }
    NSString *jsonStr = [[NSString alloc] initWithData:toJson encoding:NSUTF8StringEncoding];
    return [jsonStr stringByReplacingOccurrencesOfString:@"\"null\"" withString:@"null"];
}
@end
