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


@interface NSString (Widevine)
-(NSString*)wvAssetPath;
@end


@implementation WidevineClassicCDM

#if TARGET_OS_SIMULATOR
// The widevine library does not support the simulator, so the following are stubs that do nothing.
WViOsApiStatus WV_Initialize(const WViOsApiStatusCallback callback, NSDictionary *settings ) {
    assert(!"FATAL error: Widevine Classic is not avaialble for Simulator");
    callback(WViOsApiEvent_InitializeFailed, @{}); 
    return WViOsApiStatus_NotInitialized; 
}
WViOsApiStatus WV_Terminate() { return WViOsApiStatus_OK; }
WViOsApiStatus WV_SetCredentials( NSDictionary *settings ) { return WViOsApiStatus_OK; }
WViOsApiStatus WV_RegisterAsset (NSString *asset) { return WViOsApiStatus_OK; }
WViOsApiStatus WV_UnregisterAsset (NSString *asset) { return WViOsApiStatus_OK; }
WViOsApiStatus WV_QueryAssetStatus (NSString *asset ) { return WViOsApiStatus_OK; }
WViOsApiStatus WV_NowOnline () { return WViOsApiStatus_OK; }
WViOsApiStatus WV_RenewAsset (NSString *asset) { return WViOsApiStatus_OK; }
WViOsApiStatus WV_Play (NSString *asset, NSMutableString *url, NSData *authentication ) {[url setString:asset]; return WViOsApiStatus_OK; }
WViOsApiStatus WV_Stop () { return WViOsApiStatus_OK; }
NSString *NSStringFromWViOsApiEvent( WViOsApiEvent event ) { return @"Stub"; }
#endif

static NSMutableDictionary* assetBlocks;

static NSNumber* wvInitialized;


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
            wvInitialized = @YES;
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
            
        // Normal flow
        case WViOsApiEvent_EMMRemoved:
        case WViOsApiEvent_Unregistered:
            cdmEvent = KCDMEvent_Unregistered;
            break;
        case WViOsApiEvent_Terminated: 
            // Do nothing.
            break;
            
        // Errors
        case WViOsApiEvent_InitializeFailed:
            wvInitialized = @NO;
            break;
            
        case WViOsApiEvent_EMMFailed:
        case WViOsApiEvent_PlayFailed:
        case WViOsApiEvent_StoppingOnError: 
            // Do nothing, consider reporting to client.
            break;
            
        default:
            // Other events are just informative, don't even report them.
            ignoreEvent = YES;
            break;
    }
    
    if (ignoreEvent) {
        return WViOsApiStatus_OK;
    }
    
    NSString* assetPath = attributes[WVAssetPathKey];
    NSString* wvEventString = NSStringFromWViOsApiEvent(event);
    KPLogInfo(@"widevineCallback: event=%@ asset='%@' attr=%@", wvEventString, assetPath, attributes);
    
    if (!assetPath) {
        // Not an asset event
        return WViOsApiStatus_OK;
    }
    
    // TODO: also include relevant parsed data from attributes.
    NSDictionary* data = @{
                           @"ProviderSpecificData": attributes,
                           @"ProviderSpecificEvent": wvEventString != nil ? wvEventString : @"<null>"
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
        
        wvInitialized = @NO;
        assetBlocks = [NSMutableDictionary new];
        
        NSDictionary* settings = @{
                                   WVPortalKey: WV_PORTAL_ID,
                                   WVAssetRootKey: NSHomeDirectory(),
                                   };
        
        WViOsApiStatus wvStatus = WV_Initialize(widevineCallback, settings);
        KPLogDebug(@"WV_Initialize status: %d", wvStatus);
    }
}

+(void)setEventBlock:(KCDMAssetEventBlock)block forAsset:(NSString*)assetUri {

    // Nils not allowed.
    if (!block) {
        KPLogWarn(@"block is nil");
        return;
    }
    if (!assetUri) {
        KPLogWarn(@"assetUri is nil");
        return;
    }
    
    // only use the url part before the query string.
    NSArray* split = [assetUri componentsSeparatedByString:@"?"];
    assetUri = [split firstObject];
    
    // register using widevine's assetPath
    assetUri = assetUri.wvAssetPath;
    if (assetUri) {
        assetBlocks[assetUri] = [block copy];
    }
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
    
    // It's an error to call this function without the licenseUri.
    if (!licenseUri) {
        KPLogError(@"Error: no licenseUri; can't register asset.");
        return;
    }
    [self dispatchAfterInit:^{
        WV_SetCredentials(@{WVDRMServerKey: licenseUri});
        
        NSString* assetPath = assetUri.wvAssetPath;
        
        WViOsApiStatus wvStatus = WViOsApiStatus_OK;
        
        wvStatus = WV_RegisterAsset(assetPath);
        WV_NowOnline(); 
        WV_QueryAssetStatus(assetPath);
    }];
}

+(void)renewAsset:(NSString*)assetUri withLicenseUri:(NSString*)licenseUri {
    // It's an error to call this function without the licenseUri.
    if (!licenseUri) {
        KPLogError(@"Error: no licenseUri; can't register asset.");
        return;
    }

    [self dispatchAfterInit:^{
        WV_SetCredentials(@{WVDRMServerKey: licenseUri});
        
        NSString* assetPath = assetUri.wvAssetPath;
        
        WViOsApiStatus wvStatus = WViOsApiStatus_OK;
        
        wvStatus = WV_RenewAsset(assetPath);
        WV_NowOnline(); 
        WV_QueryAssetStatus(assetPath);
    }];
}

+(void)unregisterAsset:(NSString*)assetUri {
    NSString* assetPath = assetUri.wvAssetPath;
    WV_UnregisterAsset(assetPath);
}


+(void)checkAssetStatus:(NSString*)assetUri {
    NSString* assetPath = assetUri.wvAssetPath;

    WV_QueryAssetStatus(assetPath);
}


+(void)playAsset:(NSString *)assetUri withLicenseUri:(NSString*)licenseUri readyToPlay:(KCDMReadyToPlayBlock)block {
    
    [self dispatchAfterInit:^{
        NSMutableString* playbackURL = [NSMutableString new];
        NSString* assetPath = assetUri.wvAssetPath;
        
        // We can try playing even if we don't have the licenseUri -- if the license is already stored.
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



@implementation NSString (Widevine)

-(NSString*)wvAssetPath {
    NSString* assetUri = self;
    NSString* assetPath;
    
    if ([assetUri hasPrefix:@"file://"]) {
        // File URL -- convert to file path
        assetUri = [NSURL URLWithString:assetUri].path;
    }
    
    if ([assetUri hasPrefix:@"/"]) {
        // Downloaded file
        // Ensure it's in the home directory.
        // This is actually the simplest way to get the path of a file URL.
        NSString* homeDir = NSHomeDirectory();
        if ([assetUri hasPrefix:homeDir]) {
            assetPath = [assetUri substringFromIndex:homeDir.length];
        } else {
            KPLogError(@"Error: downloaded file is not in the home directory.");
            // will return nil
        }
    } else {
        // Online file
        assetPath = assetUri;
    }
    
    return assetPath;
}

@end





@implementation NSDictionary (Widevine)

-(NSTimeInterval)wvLicenseTimeRemaning {
    return ((NSNumber*)self[WVEMMTimeRemainingKey]).doubleValue;
}

-(NSTimeInterval)wvPurchaseTimeRemaning {
    return ((NSNumber*)self[WVPurchaseTimeRemainingKey]).doubleValue;
}

@end
