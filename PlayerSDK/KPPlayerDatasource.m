//
//  KPPlayerDatasource.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//
static NSString *WidKey = @"wid";
static NSString *UiConfIdKey = @"uiconf_id";
static NSString *CacheStKey = @"cache_st";
static NSString *EntryId = @"entry_id";
static NSString *PlayerIdKey = @"playerId";
static NSString *UridKey = @"urid";


#import "KPPlayerDatasource.h"
#import "NSString+Utilities.h"

@implementation KPPlayerDatasource
- (NSURLRequest *)videoRequest {
    NSString *link = nil;
    if (_params.root && _params.root.length) {
        [link stringByAppendingString:@"?"];
    } else {
        return nil;
    }
    if (_params.wid) {
        [link appendParam:@{WidKey: _params.wid}];
    }
    if (_params.uiConfId) {
        [link appendParam:@{UiConfIdKey: _params.uiConfId}];
    }
    if (_params.cacheSt) {
        [link appendParam:@{CacheStKey: _params.cacheSt}];
    }
    if (_params.entryId) {
        [link appendParam:@{EntryId: _params.entryId}];
    }
    if (_params.playerId) {
        [link appendParam:@{PlayerIdKey: _params.playerId}];
    }
    if (_params.urid) {
        [link appendParam:@{UridKey: _params.urid}];
    }
    if (_params.configFlags) {
        for (NSDictionary *flashVar in _params.configFlags.flashvarsArray) {
            [link appendParam:flashVar];
        }
    }
    return [NSURLRequest requestWithURL:[NSURL URLWithString:link]];
}
@end
