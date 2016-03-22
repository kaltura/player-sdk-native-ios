//
//  KPWidevineClassicHandler.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 26/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPWidevineClassicHandler.h"
#import "WidevineClassicCDM.h"

@interface KPWidevineClassicHandler () {
    NSString* _contentUrl;
    KPAssetReadyCallback _assetReadyCallback;
}
@end


@implementation KPWidevineClassicHandler

-(instancetype)initWithAssetReadyCallback:(KPAssetReadyCallback)callback {
    self = [super init];
    if (self) {
        _assetReadyCallback = [callback copy];
    }
    return self;
}

-(void)setContentUrl:(NSString*)url {
    _contentUrl = url;
}

-(void)setLicenseUri:(NSString *)licenseUri {
    [WidevineClassicCDM playAsset:_contentUrl withLicenseUri:licenseUri readyToPlay:^(NSString *playbackURL) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:playbackURL] options:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            _assetReadyCallback(asset);
        });
    }];
}

@end
