//
//  KPAssetBuilder.h
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 23/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>



@interface KPAssetBuilder : NSObject

typedef void(^KPAssetReadyCallback)(AVURLAsset* avAsset);

-(instancetype)initWithReadyCallback:(KPAssetReadyCallback)callback;
-(void)setContentUrl:(NSString*)url;
-(void)setLicenseUri:(NSString*)licenseUri;

+(void)setCertificate:(NSData*)certificate;
+(NSData*)getCertificate;


@end
