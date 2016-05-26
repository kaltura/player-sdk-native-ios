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


#define DEFAULT_CACHE_SIZE_MB   100

@interface KPPlayerConfig() {
    NSMutableDictionary *_extraConfig;
}

@property (nonatomic) NSTimeInterval startFrom;

@end

@interface KPPlayerConfigWithURL : KPPlayerConfig
-(instancetype)initWithEmbedFrameURL:(NSString *)url;
@property (nonatomic, readonly) NSString *embedFrameURL;
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
        _cacheSize = DEFAULT_CACHE_SIZE_MB;   // Default 100 MB
        return self;
    }
    return nil;
}

// Deprecated
- (instancetype)initWithDomain:(NSString *)domain uiConfID:(NSString *)uiConfId partnerId:(NSString *)partnerId {
    return [self initWithServer:domain uiConfID:uiConfId partnerId:partnerId];
}

+ (instancetype)configWithEmbedFrameURL:(NSString*)url {
    return [[KPPlayerConfigWithURL alloc ] initWithEmbedFrameURL:url];
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
    
    NSMutableString* fragment = [NSMutableString stringWithFormat:@"%@=", LocalContentId];
    if (_localContentId) {
        [fragment appendString:[_localContentId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];
    }
    if (_supportedMediaFormats) {
        [fragment appendFormat:@"&nativeSdkDrmFormats=%@", [_supportedMediaFormats[@"drm"] componentsJoinedByString:@","]];
        [fragment appendFormat:@"&nativeSdkAllFormats=%@", [_supportedMediaFormats[@"all"] componentsJoinedByString:@","]];
    }
    
    url.fragment = fragment;

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

-(id)configValueForKey:(NSString*)key {
    return _extraConfig[key];
}

@end


@implementation KPPlayerConfigWithURL

-(instancetype)initWithEmbedFrameURL:(NSString *)url
{
    self = [super init];
    if (self) {
        _embedFrameURL = url.copy;
    }
    return self;
}

- (NSURL *)videoURL {
    NSURLComponents* url = [NSURLComponents componentsWithString:_embedFrameURL];

    NSString* queryString = url.query;
    
    if (self.advertiserID) {
        queryString = [queryString appendIDFA:self.advertiserID];
    }
    if (self.enableHover) {
        queryString = queryString.appendHover;
    }
    
    url.query = queryString;
    
    if (self.supportedMediaFormats) {
        NSString* fragment = [NSString stringWithFormat:@"&nativeSdkDrmFormats=%@&nativeSdkAllFormats=%@", 
                              [self.supportedMediaFormats[@"drm"] componentsJoinedByString:@","],
                              [self.supportedMediaFormats[@"all"] componentsJoinedByString:@","]];
        if (url.fragment) {
            fragment = [url.fragment stringByAppendingString:fragment];
        }
        url.fragment = fragment;
    }    
    
    return url.URL;
}


-(void)fail:(NSString*)name {
    NSAssert(NO, @"Can't set %@ on KPPlayerConfigWithURL", name);
}
-(void)setKs:(NSString *)ks {[self fail:@"ks"];}
-(void)setEntryId:(NSString *)entryId {[self fail:@"entryId"];}
-(void)setStartFrom:(NSTimeInterval)startFrom {[self fail:@"startFrom"];}
-(void)setLocalContentId:(NSString *)localContentId {[self fail:@"localContentId"];}
-(void)addConfigKey:(NSString *)key withValue:(NSString *)value {[self fail:@"configKey"];}
-(void)addConfigKey:(NSString *)key withDictionary:(NSDictionary *)dictionary {[self fail:@"configKey"];}

@end
