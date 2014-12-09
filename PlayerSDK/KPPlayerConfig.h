//
//  KPFlashvarObject.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

/// KPPlayerConfig keys
static NSString *KPPlayerConfigNativeCallOutKey = @"nativeCallout";
static NSString *KPPlayerConfigChromecastKey = @"chromecast.plugin";
static NSString *KPPlayerConfigNativeAdIdKey = @"nativeAdId";

@interface KPPlayerConfig : NSObject

/** Adds flags for the video request
 *
 *  @param NSString The name of the flag
 *  @param NSString The value for the flag
 */
- (void)addConfigKey:(NSString *)key withValue:(NSString *)value;;

/// Contains all the added flags
@property (nonatomic, copy, readonly) NSDictionary *flashvarsDict;
@end
