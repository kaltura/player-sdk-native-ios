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

- (instancetype)initWithDomain:(NSString *)domain
                      uiConfID:(NSString *)uiConfId
                      playerID:(NSString *)playerID;

@property (nonatomic, copy) NSString *domain;
@property (nonatomic, copy) NSString *wid;
@property (nonatomic, copy) NSString *cacheSt;
@property (nonatomic, copy) NSString *urid;

@property (nonatomic, copy, readonly) NSString *uiConfId;
@property (nonatomic, copy) NSString *entryId;
@property (nonatomic, copy, readonly) NSString *playerId;


@property (nonatomic) BOOL debug;
@property (nonatomic) BOOL forceMobileHTML5;

/** Adds flags for the video request
 *
 *  @param NSString The name of the flag
 *  @param NSString The value for the flag
 */
- (void)addConfigKey:(NSString *)key withValue:(NSString *)value;;

- (NSURL *)videoURL;
@end
