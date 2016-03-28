//
//  KPLocalAssetsManager.h
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 12/01/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPPlayerConfig.h"


typedef void(^kLocalAssetRegistrationBlock)(NSError* error);
typedef void(^kLocalAssetStatusBlock)(NSError* error, NSTimeInterval expiryTime, NSTimeInterval availableTime);

@interface KPLocalAssetsManager : NSObject
+ (BOOL)registerAsset:(KPPlayerConfig *)assetConfig
               flavor:(NSString *)flavorId
                 path:(NSString *)localPath
             callback:(kLocalAssetRegistrationBlock)completed;

+ (BOOL)refreshAsset:(KPPlayerConfig *)assetConfig
               flavor:(NSString *)flavorId
                 path:(NSString *)localPath
             callback:(kLocalAssetRegistrationBlock)completed;

+ (BOOL)unregisterAsset:(KPPlayerConfig *)assetConfig
                path:(NSString *)localPath
            callback:(kLocalAssetRegistrationBlock)completed;

+ (BOOL)checkStatusForAsset:(KPPlayerConfig *)assetConfig
                       path:(NSString *)localPath
                   callback:(kLocalAssetStatusBlock)completed;

@end
