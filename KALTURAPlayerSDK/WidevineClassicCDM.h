//
//  WidevineClassicCDM.h
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 09/12/2015.
//  Copyright © 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    KCDMEvent_Null,
    KCDMEvent_AssetCanPlay,
    KCDMEvent_AssetStatus,
    KCDMEvent_LicenseAcquired,
} KCDMEventType;

typedef void(^KCDMAssetEventBlock)(KCDMEventType event, NSDictionary* data);
typedef void(^KCDMReadyToPlayBlock)(NSString* playbackURL);


@interface WidevineClassicCDM : NSObject

+(void)setEventBlock:(KCDMAssetEventBlock)block forAsset:(NSString*)assetUri;

+(void)registerLocalAsset:(NSString*)assetUri withLicenseUri:(NSString*)licenseUri;

+(void)playAsset:(NSString *)assetUri withLicenseUri:(NSString*)licenseUri readyToPlay:(KCDMReadyToPlayBlock)block;
+(void)playLocalAsset:(NSString*)assetUri readyToPlay:(KCDMReadyToPlayBlock)block;


@end
