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



@interface KPAssetBuilder ()
@property (nonatomic, copy) KPAssetReadyCallback assetReadyCallback;
@property (nonatomic, retain) id<KPAssetHandler> assetHandler;

@end


@implementation KPAssetBuilder

-(BOOL)requiresBackToForegroundHandling {
    if ([self.assetHandler respondsToSelector:@selector(backToForeground)]) {
        KPLogTrace(@"requiresBackToForegroundHandling");
        return YES;
    }
    
    return NO;
}

-(void)backToForeground {
    if ([self.assetHandler respondsToSelector:@selector(backToForeground)]) {
        [self.assetHandler backToForeground];
    }
}

-(void)setAssetParam:(NSString*)key toValue:(id)value {
    [_assetHandler setAssetParam:key toValue:value];
}

+(NSDictionary*)supportedMediaFormats {
    // We support FairPlay and Widevine Classic, as well as clear MP4 and HLS.
    return @{
#if TARGET_OS_SIMULATOR             
             // No DRM support in the simulator.
             @"all": @[@"hls",@"mp4"],
             @"drm": @[],
#else
             @"all": @[@"hls",@"wvm",@"mp4"],
             @"drm": @[@"hls",@"wvm"],
#endif
             };
}

-(instancetype)initWithReadyCallback:(KPAssetReadyCallback)callback {
    self = [super init];
    if (self) {
        self.assetReadyCallback = callback;
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

