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

@interface KPLocalAssetsManager : NSObject
+(BOOL)registerAsset:(KPPlayerConfig*)assetConfig flavor:(NSString*)flavorId path:(NSString*)localPath callback:(kLocalAssetRegistrationBlock)completed;
@end
