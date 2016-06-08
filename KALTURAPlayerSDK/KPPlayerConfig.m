//
//  KPFlashvarObject.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPPlayerConfig.h"
#import "KPPlayerConfig_Private.h"
#import "DeviceParamsHandler.h"
#import "NSString+Utilities.h"
#import "NSMutableArray+QueryItems.h"
#import "KPLog.h"


#define DEFAULT_CACHE_SIZE_MB   100
#define SERVER_CACHE_TIME       10*24*60*60 // 10 days?

@interface KPPlayerConfig() {
    NSMutableDictionary *_extraConfig;
}

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
        
        [self resolveEmbedFrameUrlWithCompletionHandler:^(BOOL success) {
            KPLogDebug(@"Resolved player URL");
        }];
        
        return self;
    }
    return nil;
}

-(BOOL)waitForPlayerRootUrl {
    // start the process, if not started yet.
    [self resolveEmbedFrameUrlWithCompletionHandler:nil];
    
    // TODO: use semaphores. But sleep is simpler and good enough.
    
    // wait for completion, up to 30 seconds.
    for (int i=0; i<30*1000/50 && !_resolvedPlayerURL; i++) {
        struct timespec delay;
        delay.tv_nsec = 50*1000*1000; // 50 millisec
        delay.tv_sec = 0;
        nanosleep(&delay, &delay);
    }
    
    return [_resolvedPlayerURL hasSuffix:@"/mwEmbedFrame.php"];
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
    
    if (![self waitForPlayerRootUrl]) {
        KPLogError(@"Can't resolve player root URL");
        return nil;
    }
    
    NSURLComponents* url = [NSURLComponents componentsWithString:_resolvedPlayerURL];
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

- (void)resolveEmbedFrameUrlWithCompletionHandler:(void (^)(BOOL success))handler {
    // In some cases, the config's server property does not point to mwEmbedFrame.php. Instead,
    // it points at "http://cdnapi.kaltura.com" or similar, and the path to mwEmbedFrame.php is taken
    // from the uiconf.
    
    NSURL *serverURL = [NSURL URLWithString:_server];
    
    if (!handler) {
        handler = ^(BOOL s) {};
    }
    
    if (_resolvedPlayerURL) {
        handler(YES);
        return;
    }
    
    if ([serverURL.path hasSuffix:@"/mwEmbedFrame.php"]) {
        // done -- pre-resolved
        _resolvedPlayerURL = _server;
        handler(YES);
        return;
    }
    
    // Could be cached, based on partnerId and uiconfId -- if not, we will cache later.
    NSString* serverConfId = [NSString stringWithFormat:@"%@/p/%@/conf/%@", serverURL, self.partnerId, self.uiConfId];
    NSDictionary* serverConf = [[NSUserDefaults standardUserDefaults] dictionaryForKey:serverConfId];
    
    
    NSString* cachedServerUrl = serverConf[@"mwEmbedFrame.php"];
    
    if (cachedServerUrl) {
        KPLogDebug(@"Cached serverURL for %@ is: %@", serverConfId, cachedServerUrl);
        // make sure the cached url is ok
        NSURL* parsedServerUrl = [NSURL URLWithString:cachedServerUrl];
        
        if ([[parsedServerUrl lastPathComponent] isEqualToString:@"mwEmbedFrame.php"]) {
            _resolvedPlayerURL = cachedServerUrl;
            handler(YES);
        } else {
            // cached url is wrong, reset it.
            cachedServerUrl = nil;
        }
    }
    
    // Even if cached, load the config to refresh the cache.
    
    // Load uiConf from Kaltrua API, get the path from there.
    [self loadUIConfWithCompletionHandler:^(NSDictionary * _Nullable uiConf, NSError * _Nullable error) {
        if (!uiConf) {
            if (!cachedServerUrl) {
                KPLogError(@"Failed loading uiConf: %@", error);
                handler(NO);
            }
            return; // handler was already called, based on cache
        }
        
        NSString *embedLoaderUrl = uiConf[@"html5Url"];
        if (![embedLoaderUrl hasSuffix:@"/mwEmbedLoader.php"]) {
            KPLogError(@"Bad html5Url property in uiConf: %@", embedLoaderUrl);
            if (!cachedServerUrl) {
                handler(NO);
            }
            return; // handler was already called, based on cache
        }
        
        // embedLoaderUrl is something like "/html5/html5lib/v2.38.3/mwEmbedLoader.php".
        // We need "/html5/html5lib/v2.38.3/mwEmbedFrame.php"
        
        NSString* embedFrameUrl = [[embedLoaderUrl stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"mwEmbedFrame.php"];
        if ([embedFrameUrl hasPrefix:@"/"]) {
            // Relative to original server URL
            NSString* url = [_server stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
            embedFrameUrl = [url stringByAppendingString:embedFrameUrl];
        }
        
        // Cache for later
        NSDictionary* newServerConf = @{
                       @"mwEmbedFrame.php": embedFrameUrl,
                       };
        [[NSUserDefaults standardUserDefaults] setObject:newServerConf forKey:serverConfId];
        
        // If not resolved by cache, mark resolved now.
        _resolvedPlayerURL = embedFrameUrl;
        if (!cachedServerUrl) {
            // Call handler if it wasn't called already based on cache
            handler(YES);
        }
    }];
}

- (void)loadUIConfWithCompletionHandler:(void (^)(NSDictionary * __nullable uiconf, NSError * __nullable error))handler {
    
    NSURL *serverURL = [NSURL URLWithString:self.server];
    serverURL = [serverURL URLByAppendingPathComponent:@"api_v3/index.php"];
    NSURLComponents *urlComps = [NSURLComponents componentsWithURL:serverURL resolvingAgainstBaseURL:NO];
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
                                                             [NSURLQueryItem queryItemWithName:@"service"   value:@"uiconf"],
                                                             [NSURLQueryItem queryItemWithName:@"action"    value:@"get"],
                                                             [NSURLQueryItem queryItemWithName:@"format"    value:@"1"],   // json
                                                             [NSURLQueryItem queryItemWithName:@"p"         value:self.partnerId],
                                                             [NSURLQueryItem queryItemWithName:@"id"        value:self.uiConfId],
                                                             ]];
    
    if (self.ks) {
        [items addObject:[NSURLQueryItem queryItemWithName:@"ks" value:self.ks]];
    }
    
    urlComps.queryItems = items;
    
    NSURL* apiCall = urlComps.URL;
    
    [[[NSURLSession sharedSession] dataTaskWithURL:apiCall completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            // Error log is printed by caller, only if needed.
            handler(nil, error);
            return;
        }
        
        NSDictionary *uiConf = [NSJSONSerialization JSONObjectWithData:data
                                                               options:0
                                                                 error:&error];
        
        if (!uiConf) {
            KPLogError(@"Error parsing uiConf json: %@", error);
            handler(nil, error);
            return;
        }
        NSString *serviceError = uiConf[@"message"];
        if (serviceError) {
            error = [NSError errorWithDomain:@"KPLocalAssetsManager"
                                         code:'uice'
                                     userInfo:@{NSLocalizedDescriptionKey: @"UIConf service error",
                                                @"UIConfID": self.uiConfId ? self.uiConfId : @"<none>",
                                                @"ServiceError": serviceError ? serviceError : @"<none>"}];
            KPLogError(@"uiConf service reported error: %@", serviceError);
            handler(nil, error);
        }

        handler(uiConf, nil);
    }] resume];
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
