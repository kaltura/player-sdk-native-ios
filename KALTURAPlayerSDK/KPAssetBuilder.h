//
//  KPAssetBuilder.h
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 23/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


typedef void(^KPAssetReadyCallback)(AVURLAsset* avAsset);

@interface KPAssetBuilder : NSObject

-(instancetype)initWithReadyCallback:(KPAssetReadyCallback)callback;
-(void)setContentUrl:(NSString*)url;
-(void)setLicenseUri:(NSString*)licenseUri;
-(void)setAssetParam:(NSString*)key toValue:(id)value;

-(void)backToForeground;

+(NSDictionary*)supportedMediaFormats;

@end


