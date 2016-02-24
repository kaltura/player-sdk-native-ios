//
//  FairPlayHandler.h
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 22/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

@import Foundation;
@import AVFoundation;
typedef NSString*(^kLicenseUriProvider)(NSString* assetId);

@interface KPFairPlayHandler : NSObject <AVAssetResourceLoaderDelegate>
-(void)setLicenseUri:(NSString*)licenseUri;
-(void)attachToAsset:(AVURLAsset*)asset;
@end
