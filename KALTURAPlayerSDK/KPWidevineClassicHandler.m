//
//  KPWidevineClassicHandler.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 26/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPWidevineClassicHandler.h"
#import "WidevineClassicCDM.h"
#import "KPLog.h"

@interface KPWidevineClassicHandler ()
@property (nonatomic, copy) NSString* contentUrl;
@property (nonatomic, copy) KPAssetReadyCallback assetReadyCallback;
@end


@implementation KPWidevineClassicHandler

-(void)setAssetParam:(NSString*)key toValue:(id)value {
    // Nothing to set
    KPLogWarn(@"Ignoring unknown asset param %@", key);
}

-(instancetype)initWithAssetReadyCallback:(KPAssetReadyCallback)callback {
    self = [super init];
    if (self) {
        self.assetReadyCallback = callback;
    }
    return self;
}

-(void)setLicenseUri:(NSString *)licenseUri {
    [WidevineClassicCDM playAsset:_contentUrl withLicenseUri:licenseUri readyToPlay:^(NSString *playbackURL) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:playbackURL] options:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_assetReadyCallback) {
                _assetReadyCallback(asset);                
            }
        });
    }];
}

@end
