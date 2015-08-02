//
//  KPFlashvarObject.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPPlayerConfig.h"
#import "DeviceParamsHandler.h"
#import "NSString+Utilities.h"
#import "KPLog.h"

/// Key names of the video request
static NSString *WidKey = @"wid";
static NSString *UiConfIdKey = @"uiconf_id";
static NSString *CacheStKey = @"cache_st";
static NSString *EntryIdKey = @"entry_id";
static NSString *PlayerIdKey = @"playerId";
static NSString *UridKey = @"urid";
static NSString *DebugKey = @"debug";
static NSString *FlashVarKey = @"flashvars";

@interface KPPlayerConfig()

@property (nonatomic, copy) NSMutableDictionary *paramsDict;
@property (nonatomic, copy) NSURL *url;
@end

@implementation KPPlayerConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _supportedInterfaceOrientations = UIInterfaceOrientationMaskAll;
        return self;
    }
    return nil;
}

- (instancetype)initWithDomain:(NSString *)domain
                      uiConfID:(NSString *)uiConfId
                      playerID:(NSString *)playerID {
    self = [self init];
    if (self && domain && uiConfId && playerID) {
        _domain = domain;
        _uiConfId = uiConfId;
        _playerId = playerID;
        [self addParam:uiConfId forKey:UiConfIdKey];
        [self addParam:playerID forKey:PlayerIdKey];
        
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

- (NSString *)createFlashvarKeyFormat:(NSString *)flashvarKey {
    if (flashvarKey && flashvarKey.length) {
        return [NSString stringWithFormat:@"%@[%@]", FlashVarKey, flashvarKey];
    }
    
    return nil;
}

- (void)addParam:(NSString *)param forKey:(NSString *)key {
    if(param && param.length && key && key.length) {
        self.paramsDict[key] = param;
    }
}

- (void)addConfigKey:(NSString *)key withValue:(NSString *)value; {
    if (key && key.length && value && value.length) {
        [self addParam:value forKey:[self createFlashvarKeyFormat:key]];
    }
}

- (void)addConfigKey:(NSString *)key withDictionary:(NSDictionary *)dictionary {
    if (key && key.length && dictionary && dictionary.count) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        
        if (!jsonData) {
            KPLogError(@"Got an error: %@", error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                         encoding:NSUTF8StringEncoding];
            [self addParam:jsonString forKey:[self createFlashvarKeyFormat:key]];
        }
    }
}

- (NSDictionary *)flashvarsDict {
    return self.paramsDict.copy;
}


- (void)setEntryId:(NSString *)entryId {
    if (entryId) {
        _entryId = entryId;
        [self addParam:entryId forKey:EntryIdKey];
    }
}

- (void)setUrid:(NSString *)urid {
    if (urid) {
        _urid = urid;
        [self addParam:urid forKey:UridKey];
    }
}

- (void)setWid:(NSString *)wid {
    if (wid) {
        _wid = wid;
        [self addParam:wid forKey:WidKey];

    }
}

- (void)setCacheSt:(NSString *)cacheSt {
    if (cacheSt) {
        _cacheSt = cacheSt;
        [self addParam:cacheSt forKey:CacheStKey];

    }
}

- (void)setDebug:(BOOL)debug {
    if (debug) {
        _debug = YES;
        [self addParam:@"true" forKey:DebugKey];

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

- (NSURL *)appendConfiguration:(NSURL *)videoURL {
    NSString *url = videoURL.absoluteString;
    if (_advertiserID) {
        url = [url appendIDFA:_advertiserID];
    }
    if (_enableHover) {
        url = url.appendHover;
    }
    url = url.appendIFrameEmbed;
    return [NSURL URLWithString:url];
}
@end
