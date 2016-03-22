//
//  KPAssetBuilder.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 23/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPAssetBuilder.h"

#import "KPAssetHandler.h"
#import "KPFairPlayHandler.h"
#import "KPWidevineClassicHandler.h"

#import "KPLog.h"

@interface KPAssetBuilder () {
    KPAssetReadyCallback _assetReadyCallback;
    id<KPAssetHandler> _assetHandler;
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

+(NSDictionary*)supportedMediaFormats {
    // Nothing dynamic: we support FairPlay and Widevine Classic, as well as clear MP4 and HLS.
    return @{
             @"all": @[@"hls",@"wvm",@"mp4"],
             @"drm": @[@"hls",@"wvm"],
             };
}

-(instancetype)initWithReadyCallback:(KPAssetReadyCallback)callback {
    self = [super init];
    if (self) {
        _assetReadyCallback = [callback copy];
    }
    return self;
}

-(void)setContentUrl:(NSString*)url {
    NSURL* contentUrl = [NSURL URLWithString:url];
    
    if (!contentUrl) {
        KPLogError(@"Failed parsing content url, can't continue");
        return;            
    }
    
    Class handlerClass;    
    if ([contentUrl.pathExtension.lowercaseString isEqualToString:@"wvm"]) {
        handlerClass = [KPWidevineClassicHandler class];
    } else {
        handlerClass = [KPFairPlayHandler class];
    }
    _assetHandler = [[handlerClass alloc] initWithAssetReadyCallback:_assetReadyCallback];
    
    [_assetHandler setContentUrl:url];
}

-(void)setLicenseUri:(NSString *)licenseUri {
    [_assetHandler setLicenseUri:licenseUri];
}

@end

