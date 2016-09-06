//
//  KPAssetRegistrationHelper.m
//  Pods
//
//  Created by Noam Tamim on 04/08/2016.
//
//

#import "KPAssetRegistrationHelper.h"
#import "KPLocalAssetsManager_Private.h"
#import "KPPlayerConfig_Private.h"
#import "KPFairPlayHandler.h"
#import "KPFairPlayAssetResourceLoaderHandler.h"
#import "KPLog.h"
#import "WidevineClassicCDM.h"
#import "KPURLProtocol.h"
#import "KCacheManager.h"
#import "NSString+Utilities.h"

#import <libkern/OSAtomic.h>

@interface KPAssetRegistrationHelper ()
@property (nonatomic, retain) KPFairPlayAssetResourceLoaderHandler* fairplayHandler;
@property (nonatomic, retain) KPPlayerConfig* config;
@property (nonatomic, copy) NSString* flavorId;
@property (nonatomic, copy) NSString* licenseUri;
@property (nonatomic) kDRMScheme drmScheme;
@end

/**
 
 Two possible flows when using this class:
 
 Widevine Classic:
 initWithAsset
 saveAssetAtPath
 
 FairPlay:
 initWithAsset
 resourceLoaderDelegate
 saveAssetAtPath

 FairPlay mode is triggered when calling resourceLoaderDelegate.
 If saveAssetAtPath is called without first calling resourceLoaderDelegate, the asset must be either Widevine or clear.

 */

#define CHECK_NOT_NULL(v)   if (!(v)) {KPLogError(@"Invalid argument for " # v); return nil;}
#define CHECK_NOT_EMPTY(v)  if (!((v).length))  {KPLogError(@"Invalid argument for " # v); return nil;}

@implementation KPAssetRegistrationHelper

-(instancetype)initWithAsset:(KPPlayerConfig *)assetConfig flavor:(NSString *)flavorId {
    self = [super init];
    if (self) {
        
        // sanitize args
        CHECK_NOT_NULL(assetConfig);
        CHECK_NOT_EMPTY(assetConfig.server);
        CHECK_NOT_EMPTY(assetConfig.entryId);
        CHECK_NOT_NULL(assetConfig.partnerId);
        CHECK_NOT_EMPTY(assetConfig.uiConfId);
        CHECK_NOT_EMPTY(assetConfig.localContentId);
        CHECK_NOT_EMPTY(flavorId);
        
        self.config = assetConfig;
        self.flavorId = flavorId;
    }
    return self;
}

-(BOOL)loadDataForDrm:(kDRMScheme)drmScheme error:(NSError* _Nonnull *)error {
    
    // If license uri is overriden, don't use our server.
    // TODO: use category method
    NSString* overrideUri = [self.config configValueForKey:@"Kaltura.overrideDrmServerURL"];
    if ([overrideUri isKindOfClass:[NSString class]]) {
        NSAssert(drmScheme != kDRMFairPlay, @"Kaltura.overrideDrmServerURL is not supported with FairPlay");         
        self.licenseUri = overrideUri;
        return YES;
    }
    
    
    NSURL* licenseDataURL = [KPLocalAssetsManager prepareGetLicenseDataURLForAsset:self.config flavorId:self.flavorId drmScheme:drmScheme error:error];
    if (!licenseDataURL) {
        return NO;
    }

    NSData *licenseData = [NSData dataWithContentsOfURL:licenseDataURL options:0 error:error];
    if (!licenseData) {
        KPLogError(@"Error getting licenseData: %@", *error);
        return NO;
    }
    
    NSDictionary *licenseDataDict = [NSJSONSerialization JSONObjectWithData:licenseData
                                                                    options:0
                                                                      error:error];
    
    if (!licenseDataDict) {
        KPLogError(@"Error parsing licenseData json: %@", error);
        return NO;
    }
    
    // parse license data
    NSDictionary *licenseDataError = licenseDataDict[@"error"];
    if (licenseDataError) {
        NSString *message = [licenseDataError isKindOfClass:[NSDictionary class]] ? licenseDataError[@"message"] : @"<none>";
        *error = [KPLocalAssetsManager errorWithCode:'lder' userInfo:@{NSLocalizedDescriptionKey: @"License data error",
                                                       @"EntryId": self.config.entryId ? self.config.entryId : @"<none>",
                                                       @"ServiceError": message ? message : @"<none>"}];
        return NO;
    }
    
    self.licenseUri = licenseDataDict[@"licenseUri"];
    
    if (drmScheme == kDRMFairPlay) {
        self.fairplayHandler = [[KPFairPlayAssetResourceLoaderHandler alloc] init];
        NSString* cert = licenseDataDict[@"fpsCertificate"];
        
        self.fairplayHandler.certificate = [[NSData alloc] initWithBase64EncodedString:cert options:0];
        self.fairplayHandler.licenseUri = self.licenseUri;
    }

    self.drmScheme = drmScheme;
    
    return YES;
}

-(id<AVAssetResourceLoaderDelegate>)createResourceLoaderDelegateWithError:(NSError**)error {

    // Only valid for FairPlay.
    NSError* err = nil;
    [self loadDataForDrm:kDRMFairPlay error:&err];
    if (error) {
        *error = err;
    }
    
    return self.fairplayHandler;
}


-(void)registerWidevineAssetAtPath:(NSString *)localPath
                     callback:(kLocalAssetRegistrationBlock)callback refresh:(BOOL)refresh {
    
    
    if (!localPath) {
        KPLogError(@"No localPath specified");
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
        [WidevineClassicCDM renewAsset:localPath withLicenseUri:self.licenseUri];
    } else {
        [WidevineClassicCDM registerLocalAsset:localPath withLicenseUri:self.licenseUri];
    }
    
}

-(NSError*)errorWithCode:(NSInteger)code userInfo:(NSDictionary*)userInfo {
    return [NSError errorWithDomain:@"KPLocalAssetsManager"
                               code:code
                           userInfo:userInfo];
}

-(void)storeLocalContentPageWithCallback:(kLocalAssetRegistrationBlock)callback {
    
    [KPURLProtocol enable];
    
    KCacheManager* cacheManager = [KCacheManager shared];
    
    cacheManager.baseURL = self.config.resolvedPlayerURL;
    cacheManager.maxCacheSize = self.config.cacheSize;
    
    NSURL* url = self.config.videoURL;
    if (!url) {
        KPLogError(@"Failed to get videoURL for asset");
        NSError* error = [self errorWithCode:'vdur' userInfo:@{NSLocalizedDescriptionKey: @"Content page error",
                                                               @"EntryId": self.config.entryId ? self.config.entryId : @"<none>"}];
        callback(error);
        [KPURLProtocol disable];
    } else {
        NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
        [KPURLProtocol ignoreLocalCacheForRequest:req];
        
        [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            callback(error);
            [KPURLProtocol disable];
        }] resume];
    }
}


// Imp: register the asset (store metadata). Call the assetRegistrationBlock when done.
-(BOOL)saveAssetAtPath:(NSURL*)localPath {
    
    __block int32_t asyncCallsLeft = 1;
    kLocalAssetRegistrationBlock done  = ^(NSError* error) {
        if (OSAtomicDecrement32(&asyncCallsLeft) == 0) {
            KPLogDebug(@"Registration finished; error: %@", error);
            if (self.assetRegistrationBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.assetRegistrationBlock(error);
                });
            } else {
                KPLogWarn(@"Registration finished but there's no assetRegistrationBlock.");
            }
        }
    };
    
    // Initiate Widevine license only if the file extension is wvm and a FairPlay delegate wasn't requested.
    if (self.drmScheme != kDRMFairPlay && localPath.path.isWV) {
        asyncCallsLeft++;
        NSError* error;
        if (![self loadDataForDrm:kDRMWidevineClassic error:&error]) {
            done(error);
        }
        
        [self registerWidevineAssetAtPath:localPath.path callback:done refresh:NO];
    }

    // For all asset types, with or without DRM, we need player metadata.
    [self storeLocalContentPageWithCallback:done];
    
    
    return YES;
}

@end



@implementation KPAssetRegistrationHelper (Factory)

+(instancetype)helperForAsset:(KPPlayerConfig *)assetConfig flavor:(NSString *)flavorId {
    return [[self alloc] initWithAsset:assetConfig flavor:flavorId];
}

@end
