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

static dispatch_queue_t	globalNotificationQueue( void )
{
    static dispatch_queue_t globalQueue = 0;
    static dispatch_once_t getQueueOnce = 0;
    dispatch_once(&getQueueOnce, ^{
        globalQueue = dispatch_queue_create("fairplay notify queue", NULL);
    });
    return globalQueue;
}

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
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:url] options:nil];
    
    [asset.resourceLoader setDelegate:self.handler queue:globalNotificationQueue()];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _assetReadyCallback(asset);
    });
}

-(void)setLicenseUri:(NSString *)licenseUri {
    self.handler.licenseUri = licenseUri;
}

@end
