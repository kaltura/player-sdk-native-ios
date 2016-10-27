//
//  FairPlayHandler.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 22/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPFairPlayHandler.h"
#import "KPFairPlayAssetResourceLoaderHandler.h"
#import "KPAssetBuilder.h"
#import "KPLog.h"
#import "NSString+Utilities.h"



@interface KPFairPlayHandler ()
@property (nonatomic, copy) KPAssetReadyCallback assetReadyCallback;
@property (nonatomic, strong) KPFairPlayAssetResourceLoaderHandler* handler;
@end

@implementation KPFairPlayHandler

-(instancetype)initWithAssetReadyCallback:(KPAssetReadyCallback)callback {
    self = [super init];
    if (self) {
        self.handler = [[KPFairPlayAssetResourceLoaderHandler alloc] init];
        self.assetReadyCallback = callback;
    }
    return self;
}

-(void)setAssetParam:(NSString*)key toValue:(id)value {
    switch (key.attributeEnumFromString) {
        case fpsCertificate:
            // value is a base64-encoded string
            self.handler.certificate = [[NSData alloc] initWithBase64EncodedString:value options:0];
            break;
            
        default:
            KPLogWarn(@"Ignoring unknown asset param %@", key);
            break;
    }
}

-(void)setContentUrl:(NSString*)url {
    NSURL* assetURL = [NSURL URLWithString:url];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
    
    [asset.resourceLoader setDelegate:self.handler queue:[KPFairPlayAssetResourceLoaderHandler globalNotificationQueue]];
    if (assetURL.isFileURL) {   // local
        asset.resourceLoader.preloadsEligibleContentKeys = YES;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _assetReadyCallback(asset);
    });
}

-(void)setLicenseUri:(NSString *)licenseUri {
    self.handler.licenseUri = licenseUri;
}

@end
