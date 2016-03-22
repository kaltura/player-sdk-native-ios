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
#import "NSMutableArray+QueryItems.h"
#import "KPLog.h"

@interface KPPlayerConfig() {
    NSMutableDictionary *_extraConfig;
}

@property (nonatomic) NSTimeInterval startFrom;

@end

@implementation KPPlayerConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _supportedInterfaceOrientations = UIInterfaceOrientationMaskAll;
        _extraConfig = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithServer:(NSString *)serverURL uiConfID:(NSString *)uiConfId partnerId:(NSString *)partnerId {
    self = [self init];
    if (self && serverURL && uiConfId && partnerId) {
        _server = serverURL;
        _uiConfId = uiConfId;
        _partnerId = partnerId;
        return self;
    }
    return nil;
}

// Deprecated
- (instancetype)initWithDomain:(NSString *)domain uiConfID:(NSString *)uiConfId partnerId:(NSString *)partnerId {
    return [self initWithServer:domain uiConfID:uiConfId partnerId:partnerId];
}

+(instancetype)configWithDictionary:(NSDictionary*)configDict {
    
    if (!configDict) {
        return nil;
    }
    
    NSDictionary* base = configDict[@"base"];
    NSDictionary* extra = configDict[@"extra"];
    
    __block KPPlayerConfig* config = [[KPPlayerConfig alloc] initWithServer:base[@"server"] uiConfID:base[@"uiConfId"] partnerId:base[@"partnerId"]];
        
    config.entryId = base[@"entryId"];
    config.ks = base[@"ks"];
    
    [extra enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isKindOfClass:NSString.class]) {
            if ([obj isKindOfClass:NSDictionary.class]) {
                [config addConfigKey:key withDictionary:obj];
            } else if ([obj isKindOfClass:NSString.class]) {
                [config addConfigKey:key withValue:obj];
            } else if ([obj isKindOfClass:NSNumber.class]) {
                [config addConfigKey:key withValue:[obj stringValue]];
            } else {
                KPLogError(@"Unsupported config value type; key=%@, value type=%@", key, [obj class]);
                config = nil;
            }
        } else {
            KPLogError(@"Config dictionary keys must be strings, got %@", [key class]);
            config = nil;
        }
    }];
    
    return config;
}

- (void)addConfigKey:(NSString *)key withValue:(NSString *)value; {
    if ([key isEqualToString:@"mediaProxy.mediaPlayFrom"] && value.doubleValue > 0.0) {
        self.startFrom = value.doubleValue;
        
        return;
    }
    
    if (key.length && value.length) {
        _extraConfig[key] = value;
    }
}

- (void)addConfigKey:(NSString *)key withDictionary:(NSDictionary *)dictionary {
    if (key.length && dictionary.count) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                           options:0
                                                             error:&error];
        
        if (!jsonData) {
            KPLogError(@"Got an error: %@", error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                         encoding:NSUTF8StringEncoding];
            [self addConfigKey:key withValue:jsonString];
        }
    }
}

-(NSMutableArray<NSURLQueryItem*>*)queryItems {
    NSMutableArray<NSURLQueryItem*>* queryItems = [NSMutableArray array];
    
    // basic fields
    [queryItems addQueryParam:@"wid" value:[@"_" stringByAppendingString:_partnerId]];
    [queryItems addQueryParam:@"uiconf_id" value:_uiConfId];
    [queryItems addQueryParam:@"entry_id" value:_entryId];
    [queryItems addQueryParam:@"ks" value:_ks];
    
    // extras
    [_extraConfig enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString* keyName = [NSString stringWithFormat:@"flashvars[%@]", key];
        [queryItems addQueryParam:keyName value:obj];
    }];
    
    return queryItems;
}

- (NSURL *)videoURL {
    NSURLComponents* url = [NSURLComponents componentsWithString:_server];
    NSMutableString* path = [url.path mutableCopy];
    [path appendFormat:@"/p/%@/sp/%@00/embedIframeJs/uiconf_id/%@", _partnerId, _partnerId, _uiConfId];
    
    if (_entryId) {
        [path appendFormat:@"/entry_id/%@", _entryId];
    } 

    NSMutableArray<NSURLQueryItem*>* queryItems = [self queryItems];
    [queryItems addQueryParam:@"iframeembed" value:@"true"];

    url.path = path;
    url.queryItems = queryItems;
    NSString *addedLocalContentId = [url.URL.absoluteString stringByAppendingFormat:@"#%@=", LocalContentId];
    if (_localContentId) {
        addedLocalContentId = [addedLocalContentId stringByAppendingString:_localContentId];
    }
    return [NSURL URLWithString:addedLocalContentId];
}

- (NSURL *)appendConfiguration:(NSURL *)videoURL {
    NSString *url = videoURL.absoluteString;
    if (_advertiserID) {
        url = [url appendIDFA:_advertiserID];
    }
    if (_enableHover) {
        url = url.appendHover;
    }
    return [NSURL URLWithString:url];
}

-(void)setEnableHover:(BOOL)enableHover {
    _enableHover = enableHover;
    [self addConfigKey:@"controlBarContainer.hover" withValue:@"true"];
}

-(void)setAdvertiserID:(NSString *)advertiserID {
    _advertiserID = advertiserID;
    [self addConfigKey:@"nativeAdId" withValue:advertiserID];

}

@end
