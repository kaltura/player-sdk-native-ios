//
//  KPFlashvarObject.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPPlayerConfig.h"
#import "DeviceParamsHandler.h"

/// Key names of the video request
static NSString *WidKey = @"wid";
static NSString *UiConfIdKey = @"uiconf_id";
static NSString *CacheStKey = @"cache_st";
static NSString *EntryIdKey = @"entry_id";
static NSString *PlayerIdKey = @"playerId";
static NSString *UridKey = @"urid";
static NSString *DebugKey = @"debug";
static NSString *ForceHtml5Key = @"forceMobileHTML5";

@interface KPPlayerConfig()

@property (nonatomic, copy) NSMutableDictionary *paramsDict;
@property (nonatomic, copy) NSURL *url;
@end

@implementation KPPlayerConfig

- (instancetype)initWithDomain:(NSString *)domain
                      uiConfID:(NSString *)uiConfId
                      playerID:(NSString *)playerID {
    self = [super init];
    if (self && domain && uiConfId && playerID) {
        _domain = domain;
        _uiConfId = uiConfId;
        _playerId = playerID;
        self.paramsDict[UiConfIdKey] = uiConfId;
        self.paramsDict[PlayerIdKey] = playerID;
        return self;
    }
    return nil;
}

- (NSMutableDictionary *)paramsDict {
    if (!_paramsDict) {
        _paramsDict = [NSMutableDictionary new];
    }
    return _paramsDict;
}

- (void)addConfigKey:(NSString *)key withValue:(NSString *)value; {
    if (key && key.length && value && value.length) {
        NSString *configKey = [NSString stringWithFormat:@"flashvars[%@]", key];
        self.paramsDict[configKey] = value;
    }
}

- (NSDictionary *)flashvarsDict {
    [self addDefaultFlags];
    return self.paramsDict.copy;
}

- (void)addDefaultFlags {
    [self addConfigKey:KPPlayerConfigNativeAdIdKey withValue:advertiserID()];
}

- (void)setEntryId:(NSString *)entryId {
    if (entryId) {
        _entryId = entryId;
        self.paramsDict[EntryIdKey] = entryId;
    }
}

- (void)setUrid:(NSString *)urid {
    if (urid) {
        _urid = urid;
        self.paramsDict[UridKey] = urid;
    }
}

- (void)setWid:(NSString *)wid {
    if (wid) {
        _wid = wid;
        self.paramsDict[WidKey] = wid;
    }
}

- (void)setCacheSt:(NSString *)cacheSt {
    if (cacheSt) {
        _cacheSt = cacheSt;
        self.paramsDict[CacheStKey] = cacheSt;
    }
}

- (void)setDebug:(BOOL)debug {
    if (debug) {
        _debug = YES;
        self.paramsDict[DebugKey] = @"true";
    }
}

- (void)setForceMobileHTML5:(BOOL)forceMobileHTML5 {
    if (forceMobileHTML5) {
        _forceMobileHTML5 = YES;
        self.paramsDict[ForceHtml5Key] = @"true";
    }
}

- (NSURL *)videoURL {
    if (!_url) {
        NSString *link = [_domain stringByAppendingString:@"?"];
        for (NSString *key in self.paramsDict.allKeys) {
            link = [link stringByAppendingFormat:@"%@=%@&", key, self.paramsDict[key]];
        }
        link = [[link substringToIndex:link.length - 1] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _url = [NSURL URLWithString:link];
    }
    return _url;
}


@end
