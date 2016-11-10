//
//  KPLocalAssetsManager_Private.h
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 09/08/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPLocalAssetsManager.h"

typedef NS_ENUM(NSUInteger, kDRMScheme) {
    kDRMNull, kDRMWidevineClassic, kDRMFairPlay
};


@interface KPLocalAssetsManager (Private)

+ (NSString *)prepareLicenseURLForAsset:(KPPlayerConfig *)assetConfig
                               flavorId:(NSString *)flavorId
                              drmScheme:(kDRMScheme)drmScheme
                                  error:(NSError **)error;

+ (NSURL *)prepareGetLicenseDataURLForAsset:(KPPlayerConfig *)assetConfig
                                   flavorId:(NSString *)flavorId
                                  drmScheme:(kDRMScheme)drmScheme error:(NSError**)error;

+(NSError*)errorWithCode:(NSInteger)code userInfo:(NSDictionary*)userInfo;

@end

