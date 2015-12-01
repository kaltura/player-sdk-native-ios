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
static NSString *EntryIdKey = @"entry_id";

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
                      partnerId:(NSString *)partnerId {
    self = [self init];
    if (self && domain && uiConfId && partnerId) {
        _domain = domain;
        _uiConfId = uiConfId;
        _partnerId = partnerId;
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
        return [NSString stringWithFormat:@"flashvars[%@]", flashvarKey];
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

- (NSURL *)videoURL {
    if (!_url) {
        NSString *link = [_domain stringByAppendingFormat:@"/p/%@/sp/%@00/embedIframeJs/uiconf_id/%@", _partnerId, _partnerId, _uiConfId];
        if (_entryId) {
            link = [link stringByAppendingFormat:@"/entry_id/%@?", _entryId];
        } else {
            link = [link stringByAppendingString:@"?"];
        }
        link = [link stringByAppendingFormat:@"wid=_%@&", _partnerId];
        
        for (NSString *key in self.paramsDict.allKeys) {
            link = [link stringByAppendingFormat:@"%@=%@&", [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]], [self.paramsDict[key] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]]];
        }

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
