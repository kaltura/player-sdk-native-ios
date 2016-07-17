//
//  KPLocalAssetsManager.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 12/01/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPLocalAssetsManager.h"
#import "KPPlayerConfig.h"
#import "KPPlayerConfig_Private.h"
#import "WidevineClassicCDM.h"
#import "NSMutableArray+QueryItems.h"
#import "KPLog.h"
#import "KPURLProtocol.h"
#import "KCacheManager.h"
#import "NSString+Utilities.h"

#import <libkern/OSAtomic.h>


@interface KPLocalAssetsManager ()
+ (NSURLQueryItem *)queryItem:(NSString *)name
                             :(NSString *)value;
@end

typedef NS_ENUM(NSUInteger, kDRMScheme) {
    kDRMWidevineClassic, kDRMWidevineCENC
};

@interface KPPlayerConfig (Asset)
@property (nonatomic, copy, readonly) NSString* overrideLicenseUri;
@end


@implementation KPLocalAssetsManager

#define CHECK_NOT_NULL(v)   if (!(v)) {KPLogError(@"Invalid argument for " # v); return NO;}
#define CHECK_NOT_EMPTY(v)  if (!((v).length))  {KPLogError(@"Invalid argument for " # v); return NO;}

+ (BOOL)registerAsset:(KPPlayerConfig *)assetConfig
               flavor:(NSString *)flavorId
                 path:(NSString *)localPath
             callback:(kLocalAssetRegistrationBlock)completed refresh:(BOOL)refresh {

    // NOTE: this method currently only supports Widevine Classic DRM.
    
    
    
    // Preflight: check that all parameters are valid.
    // TODO: not supplying these args is a programmer error, consider using NSAssert() instead.
    CHECK_NOT_NULL(assetConfig);
    CHECK_NOT_EMPTY(assetConfig.server);
    CHECK_NOT_EMPTY(assetConfig.entryId);
    CHECK_NOT_NULL(assetConfig.partnerId);
    CHECK_NOT_EMPTY(assetConfig.uiConfId);
    CHECK_NOT_EMPTY(assetConfig.localContentId);
    CHECK_NOT_EMPTY(flavorId);
    CHECK_NOT_EMPTY(localPath);
    
    __block int32_t count = localPath.isWV ? 2 : 1;
    kLocalAssetRegistrationBlock done  = ^(NSError* error) {
        if (OSAtomicDecrement32(&count) == 0) {
            completed(error);
        }
    };
    
    [self storeLocalContentPage:assetConfig callback:done];
    if (localPath.isWV) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self registerWidevineAsset:assetConfig
                              localPath:localPath
                               flavorId:flavorId
                               callback:done refresh:refresh];
        });
    }
    return YES;    
}

+ (BOOL)registerAsset:(KPPlayerConfig *)assetConfig
               flavor:(NSString *)flavorId
                 path:(NSString *)localPath
             callback:(kLocalAssetRegistrationBlock)completed {
    [KPURLProtocol enable];

    return [self registerAsset:assetConfig flavor:flavorId path:localPath callback:completed refresh:NO];
}

+ (BOOL)refreshAsset:(KPPlayerConfig *)assetConfig
              flavor:(NSString *)flavorId
                path:(NSString *)localPath
            callback:(kLocalAssetRegistrationBlock)completed {
    
    return [self registerAsset:assetConfig flavor:flavorId path:localPath callback:completed refresh:YES];
}

+ (BOOL)unregisterAsset:(KPPlayerConfig *)assetConfig
                   path:(NSString *)localPath
               callback:(kLocalAssetRegistrationBlock)completed {
    
    // Remove cache
    // TODO
    
    // TEMP, until remove cache is implemented
    if (!localPath.isWV) {
        completed(nil);
        return YES;
    }
    
    // Remove rights
    [WidevineClassicCDM setEventBlock:^(KCDMEventType event, NSDictionary *data) {
        if (event == KCDMEvent_Unregistered) {
            completed(nil);
        }
    } forAsset:localPath];
    [WidevineClassicCDM unregisterAsset:localPath];
    
    return YES;
}

+ (BOOL)checkStatusForAsset:(KPPlayerConfig *)assetConfig
                       path:(NSString *)localPath
                   callback:(kLocalAssetStatusBlock)completed {
    
    if (!localPath) {
        return NO;
    }
    
    if (!localPath.isWV) {
        completed(nil, -1, -1);
        return YES;
    }
    
    [WidevineClassicCDM setEventBlock:^(KCDMEventType event, NSDictionary *data) {
        if (event == KCDMEvent_AssetStatus) {
            completed(nil, [data wvLicenseTimeRemaning], [data wvPurchaseTimeRemaning]);
        }
    } forAsset:localPath];
    
    [WidevineClassicCDM checkAssetStatus:localPath];
    
    
    return YES;
}



+ (NSString *)prepareLicenseURLForAsset:(KPPlayerConfig *)assetConfig
                               flavorId:(NSString *)flavorId
                              drmScheme:(kDRMScheme)drmScheme
                                  error:(NSError **)error {
    
    
    
    // If license uri is overriden, don't use our server.
    NSString* overrideUri = assetConfig.overrideLicenseUri;
    if (overrideUri) {
        return overrideUri;
    }
    
    
    // load license data
    NSURL *getLicenseDataURL = [self prepareGetLicenseDataURLForAsset:assetConfig
                                                             flavorId:flavorId
                                                            drmScheme:drmScheme error:error];
    
    if (!getLicenseDataURL) {
        return nil;
    }
    
    NSData *licenseData = [NSData dataWithContentsOfURL:getLicenseDataURL options:0 error:error];
    if (!licenseData) {
        KPLogError(@"Error getting licenseData: %@", *error);
        return nil;
    }

    NSDictionary *licenseDataDict = [NSJSONSerialization JSONObjectWithData:licenseData
                                                                    options:0
                                                                      error:error];
    
    if (!licenseDataDict) {
        KPLogError(@"Error parsing licenseData json: %@", *error);
        return nil;
    }
    
    // parse license data
    NSDictionary *licenseDataError = licenseDataDict[@"error"];
    if (licenseDataError) {
        NSString *message = [licenseDataError isKindOfClass:[NSDictionary class]] ? licenseDataError[@"message"] : @"<none>";
        *error = [self errorWithCode:'lder' userInfo:@{NSLocalizedDescriptionKey: @"License data error",
                                                               @"EntryId": assetConfig.entryId ? assetConfig.entryId : @"<none>",
                                                       @"ServiceError": message ? message : @"<none>"}];
        return nil;
    }
    
    NSString* licenseUri = licenseDataDict[@"licenseUri"];
    
    return licenseUri;
}

+ (NSURL *)prepareGetLicenseDataURLForAsset:(KPPlayerConfig *)assetConfig
                                   flavorId:(NSString *)flavorId
                                  drmScheme:(kDRMScheme)drmScheme error:(NSError**)error {
    
    if (![assetConfig waitForPlayerRootUrl]) {
        *error = [self errorWithCode:'purl' userInfo:@{NSLocalizedDescriptionKey: @"Failed to resolve player URL, can't continue"}];
        return nil;
    }
    
    NSURL *serverURL = [NSURL URLWithString:assetConfig.resolvedPlayerURL];
    serverURL = [serverURL URLByDeletingLastPathComponent];

    if (!serverURL) {
        return nil;
    }
    
    // Now serviceURL is something like "http://cdnapi.kaltura.com/html5/html5lib/v2.38.3".
    NSString* drmName = nil; 
    
    switch (drmScheme) {
        case kDRMWidevineCENC:
            drmName = @"wvcenc";
            break;
        case kDRMWidevineClassic:
            drmName = @"wvclassic";
            break;
    }
    
    // Build service URL
    NSURL* serviceURL = [serverURL URLByAppendingPathComponent:@"services.php"];
    NSURLComponents* url = [NSURLComponents componentsWithURL:serviceURL resolvingAgainstBaseURL:NO];
    
    NSMutableArray<NSURLQueryItem*>* queryItems = assetConfig.queryItems;
    [queryItems addQueryParam:@"service" value:@"getLicenseData"];
    [queryItems addQueryParam:@"drm" value:drmName];
    [queryItems addQueryParam:@"flavor_id" value:flavorId];

    url.queryItems = queryItems;
    
    serviceURL = [url URL];
    
    return serviceURL;

}

+ (void)registerWidevineAsset:(KPPlayerConfig *)assetConfig
                    localPath:(NSString *)localPath
                     flavorId:(NSString *)flavorId
                     callback:(kLocalAssetRegistrationBlock)callback refresh:(BOOL)refresh {
    
    
    if (!localPath) {
        KPLogError(@"No localPath specified");
        return;
    }
    
    NSError *error = nil;
    NSString *licenseUri = [self prepareLicenseURLForAsset:assetConfig
                                                  flavorId:flavorId
                                                 drmScheme:kDRMWidevineClassic
                                                     error:&error];
    if (!licenseUri) {
        KPLogError(@"Error getting license data: %@", error);
        callback(error);
        return;
    }
    
    [WidevineClassicCDM setEventBlock:^(KCDMEventType event, NSDictionary *data) {
        
        switch (event) {
            case KCDMEvent_LicenseAcquired:
                    callback(nil);
                break;
            case KCDMEvent_FileNotFound:
                callback([self errorWithCode:'fnfd' userInfo:@{NSLocalizedDescriptionKey: @"Widevine file not found",
                                                               @"LocalPath": localPath}]);
                break;
                
            default:
                break;
        }
        KPLogDebug(@"Got asset event: event=%d, data=%@", event, data);
    } forAsset:localPath];
    
    if (refresh) {
        [WidevineClassicCDM renewAsset:localPath withLicenseUri:licenseUri];
    } else {
        [WidevineClassicCDM registerLocalAsset:localPath withLicenseUri:licenseUri];
    }
    
}

+(NSError*)errorWithCode:(NSInteger)code userInfo:(NSDictionary*)userInfo {
    return [NSError errorWithDomain:@"KPLocalAssetsManager"
                               code:code
                           userInfo:userInfo];
}

+ (void)storeLocalContentPage:(KPPlayerConfig *)assetConfig
                     callback:(kLocalAssetRegistrationBlock)callback {

    [KPURLProtocol enable];
    
    KCacheManager* cacheManager = [KCacheManager shared];
    
    cacheManager.baseURL = assetConfig.resolvedPlayerURL;
    cacheManager.maxCacheSize = assetConfig.cacheSize;

    NSURL* url = assetConfig.videoURL;
    if (!url) {
        KPLogError(@"Failed to get videoURL for asset");
        NSError* error = [self errorWithCode:'vdur' userInfo:@{NSLocalizedDescriptionKey: @"Content page error",
                                                               @"EntryId": assetConfig.entryId ? assetConfig.entryId : @"<none>"}];
        callback(error);
        [KPURLProtocol disable];
    } else {
        [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            callback(error);
            [KPURLProtocol disable];
        }] resume];
    }
}

+ (void)addQueryParameters:(NSDictionary *)queryParams
           toURLComponents:(NSURLComponents *)components {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:queryParams.count];
    [queryParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [array addObject:[NSURLQueryItem queryItemWithName:key value:obj]];
    }];
    components.queryItems = array;
}

+ (NSURLQueryItem *)queryItem:(NSString *)name
                             :(NSString *)value {
    return [NSURLQueryItem queryItemWithName:name value:value];
}

@end





@implementation KPPlayerConfig (Asset)


-(NSString*)overrideLicenseUri {
    NSString* override = [self configValueForKey:@"Kaltura.overrideDrmServerURL"];
    return [override isKindOfClass:[NSString class]] ? override : nil;
}


@end

