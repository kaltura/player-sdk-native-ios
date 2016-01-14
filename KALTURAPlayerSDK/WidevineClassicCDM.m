//
//  WidevineClassicCDM.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 09/12/2015.
//  Copyright © 2015 Kaltura. All rights reserved.
//

#import "WidevineClassicCDM.h"

#import "WViPhoneAPI.h"

#import "KPLog.h"

#define WV_PORTAL_ID @"kaltura"

@implementation WidevineClassicCDM

#if TARGET_OS_SIMULATOR
// The widevine library does not support the simulator, so the following are stubs that do nothing.
WViOsApiStatus WV_Initialize(const WViOsApiStatusCallback callback, NSDictionary *settings ) { callback(WViOsApiEvent_Initialized, @{}); return WViOsApiStatus_OK; }
WViOsApiStatus WV_Terminate() { return WViOsApiStatus_OK; }
WViOsApiStatus WV_SetCredentials( NSDictionary *settings ) { return WViOsApiStatus_OK; }
WViOsApiStatus WV_RegisterAsset (NSString *asset) { return WViOsApiStatus_OK; }
WViOsApiStatus WV_QueryAssetStatus (NSString *asset ) { return WViOsApiStatus_OK; }
WViOsApiStatus WV_NowOnline () { return WViOsApiStatus_OK; }
WViOsApiStatus WV_RenewAsset (NSString *asset) { return WViOsApiStatus_OK; }
WViOsApiStatus WV_Play (NSString *asset, NSMutableString *url, NSData *authentication ) {[url setString:asset]; return WViOsApiStatus_OK; }
WViOsApiStatus WV_Stop () { return WViOsApiStatus_OK; }
NSString *NSStringFromWViOsApiEvent( WViOsApiEvent event ) { return @"Stub"; }
#endif

static NSMutableDictionary* assetBlocks;

static NSNumber* wvInitialized;

+(NSString*)getAssetPath:(NSString*)assetUri {
    NSString* assetPath;
    
    if ([assetUri hasPrefix:@"file://"]) {
        // File URL -- convert to file path
        assetUri = [NSURL URLWithString:assetUri].path;
    }
    
    if ([assetUri hasPrefix:@"/"]) {
        // Downloaded file
        // Ensure it's in the documents directory.
        // This is actually the simplest way to get the path of a file URL.
        NSString* docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        
        if ([assetUri hasPrefix:docDir]) {
            assetPath = [assetUri substringFromIndex:docDir.length];
        } else {
            KPLogError(@"Error: downloaded file is not in the Documents directory.");
            // will return nil
        }
    } else {
        // Online file
        assetPath = assetUri;
    }
    
    return assetPath;
}

+(void)dispatchAfterInit:(dispatch_block_t)block {
    
    // TODO: assuming initialization takes less than 200 msec. 
    
    if ([wvInitialized boolValue]) {
        if ([NSThread isMainThread]) {
            block();
        } else {
            dispatch_sync(dispatch_get_main_queue(), block);
        }
        return;
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 200 * NSEC_PER_MSEC), dispatch_get_main_queue(), block);
    }
}

static WViOsApiStatus widevineCallback(WViOsApiEvent event, NSDictionary *attributes) {
    return [WidevineClassicCDM widevineCallbackWithEvent:event attr:attributes];
}

+(WViOsApiStatus)widevineCallbackWithEvent:(WViOsApiEvent)event attr:(NSDictionary*)attributes {
    
    BOOL ignoreEvent = NO;
    KCDMEventType cdmEvent = KCDMEvent_Null;
    
    switch (event) {
        // Normal flow
        case WViOsApiEvent_Initialized:
            wvInitialized = [NSNumber numberWithBool:YES];
            break;
            
        case WViOsApiEvent_Registered: break;
        case WViOsApiEvent_EMMReceived: 
            cdmEvent = KCDMEvent_LicenseAcquired;
            break;
            
        case WViOsApiEvent_Playing:
            cdmEvent = KCDMEvent_AssetCanPlay;
            break;
            
        case WViOsApiEvent_Stopped: break;
            
        case WViOsApiEvent_QueryStatus:
            cdmEvent = KCDMEvent_AssetStatus;
            break;
            
        case WViOsApiEvent_EMMRemoved: break;
        case WViOsApiEvent_Unregistered: break;
        case WViOsApiEvent_Terminated: break;
            
        // Errors
        case WViOsApiEvent_InitializeFailed:
            wvInitialized = [NSNumber numberWithBool:NO];
            break;
            
        case WViOsApiEvent_EMMFailed: break;
        case WViOsApiEvent_PlayFailed: break;
        case WViOsApiEvent_StoppingOnError: break;
            
        default:
            // Other events are just informative
            ignoreEvent = YES;
            break;
    }
    
    if (ignoreEvent) {
        return WViOsApiStatus_OK;
    }
    
    NSString* assetPath = attributes[WVAssetPathKey];
    NSLog(@"widevineCallback: event=%@ asset='%@' attr=%@", NSStringFromWViOsApiEvent(event), assetPath, attributes);
    
    if (!assetPath) {
        // Not an asset event
        return WViOsApiStatus_OK;
    }
    
    // TODO: also include relevant parsed data from attributes.
    NSDictionary* data = @{
                           @"ProviderSpecificData": attributes,
                           @"ProviderSpecificEvent": NSStringFromWViOsApiEvent(event)
                           };
    
    [self callAssetBlockFor:assetPath event:cdmEvent data:data];
    
    return WViOsApiStatus_OK;

}

+ (void)initialize {
    
    if (wvInitialized) {
        return;
    }
    
    @synchronized([self class]) {
        
        if (wvInitialized) {
            return;
        }
        
        wvInitialized = [NSNumber numberWithBool:NO];
        assetBlocks = [NSMutableDictionary new];
        
        NSDictionary* settings = @{WVPortalKey: WV_PORTAL_ID};
        
        WViOsApiStatus wvStatus = WV_Initialize(widevineCallback, settings);
        KPLogDebug(@"WV_Initialize status: %d", wvStatus);
    }
}

+(void)setEventBlock:(KCDMAssetEventBlock)block forAsset:(NSString*)assetUri {
    
    // only use the url part before the query string.
    NSArray* split = [assetUri componentsSeparatedByString:@"?"];
    assetUri = [split firstObject];
    
    // register using widevine's assetPath
    assetUri = [self getAssetPath:assetUri];
    
    assetBlocks[assetUri] = [block copy];
}

+(void)callAssetBlockFor:(NSString*)assetPath event:(KCDMEventType)event data:(NSDictionary*)data {
    
    // only use the url part before the query string.
    NSArray* split = [assetPath componentsSeparatedByString:@"?"];
    assetPath = [split firstObject];
    
    KCDMAssetEventBlock assetBlock = assetBlocks[assetPath];

    if (assetBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            assetBlock(event, data);
        });
    }
}

+(void)registerLocalAsset:(NSString*)assetUri withLicenseUri:(NSString*)licenseUri {
    
    [self dispatchAfterInit:^{
        WV_SetCredentials(@{WVDRMServerKey: licenseUri});
        
        NSString* assetPath = [self getAssetPath:assetUri];
        
        WViOsApiStatus wvStatus = WViOsApiStatus_OK;
        
        wvStatus = WV_RegisterAsset(assetPath);
        // refresh licenses if required.
        WV_RenewAsset(assetPath);
        WV_NowOnline(); 
        WV_QueryAssetStatus(assetPath);
    }];
}

+(void)playAsset:(NSString *)assetUri withLicenseUri:(NSString*)licenseUri readyToPlay:(KCDMReadyToPlayBlock)block {
    
    [self dispatchAfterInit:^{
        NSMutableString* playbackURL = [NSMutableString new];
        NSString* assetPath = [self getAssetPath:assetUri];
        
        if (licenseUri) {
            WV_SetCredentials(@{WVDRMServerKey: licenseUri});
        }
        
        WViOsApiStatus status = WV_Play(assetPath, playbackURL, nil);
        if (status == WViOsApiStatus_AlreadyPlaying) {
            WV_Stop();
            status = WV_Play(assetPath, playbackURL, nil);
        }
        if (block) {
            block([playbackURL copy]);
        }
    }];

}

+(void)playLocalAsset:(NSString*)assetUri readyToPlay:(KCDMReadyToPlayBlock)block {
    [self playAsset:assetUri withLicenseUri:nil readyToPlay:block];
}

@end
