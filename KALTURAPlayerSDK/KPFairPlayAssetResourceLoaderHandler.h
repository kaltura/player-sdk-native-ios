//
//  KPFairPlayAssetResourceLoaderHandler.h
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 09/08/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

@import AVFoundation;

@interface KPFairPlayAssetResourceLoaderHandler : NSObject <AVAssetResourceLoaderDelegate>
@property (nonatomic, copy) NSString* licenseUri;
@property (nonatomic, copy) NSData* certificate;
@end
