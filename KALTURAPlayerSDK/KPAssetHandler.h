//
//  KPAssetHandler.h
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 22/03/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

// Protocol used by KPAssetBuilder to handle DRM operations for an asset.

#import "KPAssetBuilder.h"

@protocol KPAssetHandler <NSObject>

-(instancetype)initWithAssetReadyCallback:(KPAssetReadyCallback)callback;

-(void)setContentUrl:(NSString*)contentUrl;
-(void)setLicenseUri:(NSString*)licenseUri;
-(void)setAssetParam:(NSString*)key toValue:(id)value;

@optional
-(void)backToForeground;

@end
