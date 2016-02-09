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

@interface KPPlayerConfig() {
    NSMutableDictionary *_extraConfig;
}
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
        _extraConfig = [NSMutableDictionary dictionary];
        return self;
    }
    return nil;
}

- (void)addConfigKey:(NSString *)key withValue:(NSString *)value; {
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

-(void)addParam:(NSString*)key value:(NSString*)value toArray:(NSMutableArray<NSURLQueryItem*>*)array {
    if (key.length && value.length) {
        [array addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }
}

-(NSMutableArray<NSURLQueryItem*>*)queryItems {
    NSMutableArray<NSURLQueryItem*>* queryItems = [NSMutableArray array];
    
    // basic fields
    [self addParam:@"wid" value:[@"_" stringByAppendingString:_partnerId] toArray:queryItems];
    [self addParam:@"uiconf_id" value:_uiConfId toArray:queryItems];
    [self addParam:@"entry_id" value:_entryId toArray:queryItems];
    [self addParam:@"ks" value:_ks toArray:queryItems];
    
    // extras
    [_extraConfig enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString* keyName = [NSString stringWithFormat:@"flashvars[%@]", key];
        [self addParam:keyName value:obj toArray:queryItems];
    }];
    
    return queryItems;
}

- (NSURL *)videoURL {
    NSURLComponents* url = [NSURLComponents componentsWithString:_domain];
    NSMutableString* path = [NSMutableString stringWithFormat:@"/p/%@/sp/%@00/embedIframeJs/uiconf_id/%@", _partnerId, _partnerId, _uiConfId];
    
    if (_entryId) {
        [path appendFormat:@"/entry_id/%@", _entryId];
    } 

    NSMutableArray<NSURLQueryItem*>* queryItems = [self queryItems];
    [self addParam:@"iframeembed" value:@"true" toArray:queryItems];

    url.path = path;
    url.queryItems = queryItems;

    return url.URL;
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

-(void)setEnableHover:(BOOL)enableHover {
    _enableHover = enableHover;
    [self addConfigKey:@"controlBarContainer.hover" withValue:@"true"];
}

-(void)setAdvertiserID:(NSString *)advertiserID {
    _advertiserID = advertiserID;
    [self addConfigKey:@"nativeAdId" withValue:advertiserID];

}

@end
