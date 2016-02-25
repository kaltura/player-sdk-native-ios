//
//  KPAssetBuilder.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 23/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPAssetBuilder.h"
#import "KPFairPlayHandler.h"
#import "KPViewControllerProtocols.h"
#import "KPLog.h"
#import "KPlayerFactory.h"
#import "WidevineClassicCDM.h"

@interface KPAssetBuilder () {
    kDRMScheme _drm;
    NSURL* _contentUrl;
    NSString* _licenseUri;
    KPAssetReadyCallback _assetReadyCallback;
    
    // DRM specific
    NSURL* _wvPlaybackUrl;
    KPFairPlayHandler* _fairplayHandler;
}
@end

@implementation KPAssetBuilder

static NSData* s_certificate;

+(void)setCertificate:(NSData*)certificate {
    s_certificate = certificate;
}

+(NSData*)getCertificate {
    return s_certificate;
}

-(instancetype)initWithReadyCallback:(KPAssetReadyCallback)callback {
    self = [super init];
    if (self) {
        _assetReadyCallback = callback;
    }
    return self;
}

-(void)setContentUrl:(NSString*)url {
    _contentUrl = [NSURL URLWithString:url];
    
    if (!_contentUrl) {
        return;            
    }
    
    if ([_contentUrl.pathExtension.lowercaseString isEqualToString:@"wvm"]) {
        _drm = kDRMWidevineClassic;
    } else {
        _drm = kDRMFairPlay;
        _fairplayHandler = [KPFairPlayHandler new];
        [self callAssetReadyCallback]; // always ready
    }
}

-(AVURLAsset*)toAVAsset {
    AVURLAsset *asset;
    switch (_drm) {
        case kDRMFairPlay:
            asset = [AVURLAsset URLAssetWithURL:_contentUrl options:nil];
            [_fairplayHandler attachToAsset:asset];
            break;
            
        case kDRMWidevineClassic:
            asset = [AVURLAsset URLAssetWithURL:_wvPlaybackUrl options:nil];
            break;
            
        case kDRMWidevineCENC:
            KPLogError(@"Widevine CENC is not supported");
            break;
    }
    
    return asset;
}

-(void)callAssetReadyCallback {
    if (_assetReadyCallback) {
        AVURLAsset* avAsset = self.toAVAsset;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            _assetReadyCallback(avAsset);
        });
    }
}

-(void)playWidevineClassicAsset {
    // Widevine: license acq and get playback url
    [WidevineClassicCDM playAsset:_contentUrl.absoluteString withLicenseUri:_licenseUri readyToPlay:^(NSString *playbackURL) {
        _wvPlaybackUrl = [NSURL URLWithString:playbackURL];
        [self callAssetReadyCallback];
    }];
}

-(void)setLicenseUri:(NSString *)licenseUri {
    _licenseUri = licenseUri;

    switch (_drm) {
        case kDRMFairPlay:
            [_fairplayHandler setLicenseUri:_licenseUri];
            break;
            
        case kDRMWidevineClassic:
            [self playWidevineClassicAsset];
            break;
            
        case kDRMWidevineCENC:
            KPLogError(@"Widevine CENC is not supported");
            break;
    }
}

@end
