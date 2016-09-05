//
//  KPLocalAssetsManager.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 12/01/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPLocalAssetsManager.h"
#import "KPLocalAssetsManager_Private.h"
#import "KPAssetRegistrationHelper.h"
#import "KPPlayerConfig.h"
#import "KPPlayerConfig_Private.h"
#import "WidevineClassicCDM.h"
#import "NSMutableArray+QueryItems.h"
#import "KPLog.h"
#import "KPURLProtocol.h"
#import "KCacheManager.h"
#import "NSString+Utilities.h"

#import <libkern/OSAtomic.h>



@implementation KPLocalAssetsManager

#define CHECK_NOT_NULL(v)   if (!(v)) {KPLogError(@"Invalid argument for " # v); return NO;}
#define CHECK_NOT_EMPTY(v)  if (!((v).length))  {KPLogError(@"Invalid argument for " # v); return NO;}

+ (BOOL)registerAsset:(KPPlayerConfig *)assetConfig
               flavor:(NSString *)flavorId
                 path:(NSString *)localPath
             callback:(kLocalAssetRegistrationBlock)completed refresh:(BOOL)refresh {

    // NOTE: the only DRM scheme supported by this method is Widevine Classic.
    
    [KPURLProtocol enable];

    KPAssetRegistrationHelper* helper = [KPAssetRegistrationHelper helperForAsset:assetConfig flavor:flavorId];
    if (!helper) {
        return NO;
    }
    helper.refresh = refresh;
    helper.assetRegistrationBlock = completed;
    return [helper saveAssetAtPath:[NSURL fileURLWithPath:localPath]];
}

+ (BOOL)registerAsset:(KPPlayerConfig *)assetConfig
               flavor:(NSString *)flavorId
                 path:(NSString *)localPath
             callback:(kLocalAssetRegistrationBlock)completed {

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

+ (NSURL *)prepareGetLicenseDataURLForAsset:(KPPlayerConfig *)assetConfig
                                   flavorId:(NSString *)flavorId
                                  drmScheme:(kDRMScheme)drmScheme error:( NSError* _Nonnull *)error {
    
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
        case kDRMFairPlay:
            drmName = @"fps";
            break;
        case kDRMWidevineClassic:
            drmName = @"wvclassic";
            break;
        case kDRMNull:
            return nil;
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

+(NSError*)errorWithCode:(NSInteger)code userInfo:(NSDictionary*)userInfo {
    return [NSError errorWithDomain:@"KPLocalAssetsManager"
                               code:code
                           userInfo:userInfo];
}

@end

