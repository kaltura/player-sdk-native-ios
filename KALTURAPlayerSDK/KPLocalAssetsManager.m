//
//  KPLocalAssetsManager.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 12/01/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPLocalAssetsManager.h"
#import "KPPlayerConfig.h"
#import "WidevineClassicCDM.h"
#import "KPLog.h"


typedef NS_ENUM(NSUInteger, kDRMScheme) {
    kDRMWidevineClassic, kDRMWidevineCENC
};


@implementation KPLocalAssetsManager


#define JSON_BYTE_LIMIT = 1024 * 1024;

#define CHECK_NOT_NULL(v)   if (!(v)) return NO
#define CHECK_NOT_EMPTY(v)  if ((v).length == 0) return NO

+(BOOL)registerAsset:(KPPlayerConfig*)assetConfig flavor:(NSString*)flavorId path:(NSString*)localPath callback:(kLocalAssetRegistrationBlock)completed {
    
    // NOTE: this method currently only supports (and assumes) Widevine Classic.

    // Preflight: check that all parameters are valid.
    CHECK_NOT_NULL(assetConfig);
    CHECK_NOT_EMPTY(assetConfig.domain);
    CHECK_NOT_EMPTY(assetConfig.ks);
    CHECK_NOT_EMPTY(assetConfig.entryId);
    CHECK_NOT_EMPTY(assetConfig.partnerId);
    CHECK_NOT_EMPTY(assetConfig.uiConfId);
    CHECK_NOT_EMPTY(flavorId);
    CHECK_NOT_EMPTY(localPath);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self registerWidevineAsset:assetConfig localPath:localPath flavorId:flavorId callback:completed];
    });
    
    return YES;
}

+(NSString*)prepareLicenseURLForAsset:(KPPlayerConfig*)assetConfig flavorId:(NSString*)flavorId drmScheme:(kDRMScheme)drmScheme {
    
    // load license data
    NSURL* getLicenseDataURL = [self prepareGetLicenseDataURLForAsset:assetConfig flavorId:flavorId drmScheme:drmScheme];
    NSData* licenseData = [NSData dataWithContentsOfURL:getLicenseDataURL];
    NSDictionary* licenseDataDict = [NSJSONSerialization JSONObjectWithData:licenseData options:0 error:nil];
    
    // parse license data
    if (licenseDataDict[@"error"]) {
        // TODO: report the error 
        return nil; // licenseDataDict[@"error"][@"message"];
    }
    
    NSDictionary* licenseUris = licenseDataDict[@"licenseUri"];
    
    return licenseUris[flavorId];
}

+(NSURL*)prepareGetLicenseDataURLForAsset:(KPPlayerConfig*)assetConfig flavorId:(NSString*)flavorId drmScheme:(kDRMScheme)drmScheme {
    
    NSURL* serverURL = [NSURL URLWithString:assetConfig.domain];
    
    // URL may either point to the root of the server or to mwEmbedFrame.php. Resolve this.
    if ([serverURL.path hasSuffix:@"/mwEmbedFrame.php"]) {
        serverURL = [serverURL URLByDeletingLastPathComponent];
    } else {
        serverURL = [self resolvePlayerRootURL:serverURL partnerId:assetConfig.partnerId uiConfId:assetConfig.uiConfId ks:assetConfig.ks];
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
    [NSURLQueryItem queryItemWithName:@"service" value:@"getLicenseData"];
    
    [url setQueryItems:@[
                         [self queryItem:@"service"   :@"getLicenseData"],
                         [self queryItem:@"ks"        :assetConfig.ks],
                         [self queryItem:@"wid"       :assetConfig.partnerId],
                         [self queryItem:@"entry_id"  :assetConfig.entryId],
                         [self queryItem:@"uiconf_id" :assetConfig.uiConfId],
                         [self queryItem:@"drm"       :drmName],
                         ]];

    serviceURL = [url URL];
    
    return serviceURL;

}

+(void)registerWidevineAsset:(KPPlayerConfig*)assetConfig localPath:(NSString*)localPath flavorId:(NSString*)flavorId callback:(kLocalAssetRegistrationBlock)callback {
    
    NSString* licenseUri = [self prepareLicenseURLForAsset:assetConfig flavorId:flavorId drmScheme:kDRMWidevineClassic];
    if (!licenseUri) {
        KPLogError(@"Failed to retreive licenseUri for asset %@", localPath);
        NSError* error = [NSError errorWithDomain:@"KPLocalAssetsManager" code:'LURF' 
                                         userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to retreive licenseUri for asset", nil),
                                                    @"LocalAssetPath": localPath}];

        callback(error);
        return;
    }
    
    [WidevineClassicCDM setEventBlock:^(KCDMEventType event, NSDictionary *data) {
        
        switch (event) {
            case KCDMEvent_LicenseAcquired:
                callback(nil);
                break;
                
            default:
                break;
        }
        KPLogDebug(@"Got asset event: event=%d, data=%@", event, data);
    } forAsset:localPath];
    [WidevineClassicCDM registerLocalAsset:localPath withLicenseUri:licenseUri];
    
}

+(NSURL*)resolvePlayerRootURL:(NSURL*)serverURL partnerId:(NSString*)partnerId uiConfId:(NSString*)uiConfId ks:(NSString*)ks {
    
    // serverURL is something like "http://cdnapi.kaltura.com"; 
    // we need to get to "http://cdnapi.kaltura.com/html5/html5lib/v2.38.3".
    // This is done by loading UIConf data, and looking at "html5Url" property.
    
    NSData* jsonData = [self loadUIConf:uiConfId partnerId:partnerId ks:ks serverURL:serverURL];
    NSDictionary* uiConf = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];

    if (uiConf[@"message"]) {
        return nil; // TODO: report error
    }
    
    NSString* embedLoaderUrl = uiConf[@"html5Url"];
    
    // embedLoaderUrl is typically something like "/html5/html5lib/v2.38.3/mwEmbedLoader.php".
    
    if ([embedLoaderUrl hasPrefix:@"/"]) {
        serverURL = [serverURL URLByAppendingPathComponent:embedLoaderUrl];
    } else {
        serverURL = [NSURL URLWithString:embedLoaderUrl];
    }
    
    return [serverURL URLByDeletingLastPathComponent];
}

+(void)addQueryParameters:(NSDictionary*)queryParams toURLComponents:(NSURLComponents*)components {
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:queryParams.count];
    [queryParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [array addObject:[NSURLQueryItem queryItemWithName:key value:obj]];
    }];
    components.queryItems = array;
}

+(NSURLQueryItem*)queryItem:(NSString*)name :(NSString*)value {
    return [NSURLQueryItem queryItemWithName:name value:value];
}

+(NSData*)loadUIConf:(NSString*)uiConfId partnerId:(NSString*)partnerId ks:(NSString*)ks serverURL:(NSURL*)serverURL {
    
    serverURL = [serverURL URLByAppendingPathComponent:@"api_v3/index.php"];
    NSURLComponents* urlComps = [NSURLComponents componentsWithURL:serverURL resolvingAgainstBaseURL:NO];
    
    NSMutableArray* items = [NSMutableArray arrayWithArray:@[
                                                             [self queryItem:@"service" :@"uiconf"],
                                                             [self queryItem:@"action" :@"get"],
                                                             [self queryItem:@"format" :@"1"],
                                                             [self queryItem:@"p" :partnerId],
                                                             [self queryItem:@"id" :uiConfId],
                                                             ]];
    
    if (ks) {
        [items addObject:[self queryItem:@"ks" :ks]];
    }
    
    NSURL* apiCall = urlComps.URL;
    
    return [NSData dataWithContentsOfURL:apiCall];
}

@end
