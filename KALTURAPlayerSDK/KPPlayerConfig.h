//
//  KPFlashvarObject.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KPCacheConfig.h"

/// KPPlayerConfig keys
static NSString *KPPlayerConfigNativeCallOutKey = @"nativeCallout";
static NSString *KPPlayerConfigChromecastKey = @"chromecast.plugin";
static NSString *KPPlayerConfigNativeAdIdKey = @"nativeAdId";




@interface KPPlayerConfig : NSObject

- (instancetype)initWithServer:(NSString *)serverURL uiConfID:(NSString *)uiConfId partnerId:(NSString *)partnerId;

- (instancetype)initWithDomain:(NSString *)domain uiConfID:(NSString *)uiConfId partnerId:(NSString *)partnerId
DEPRECATED_MSG_ATTRIBUTE("Use initWithServer:uiConfID:partnerId:");

+ (instancetype)configWithEmbedFrameURL:(NSString*)url;

+(instancetype)configWithServer:(NSString *)serverURL uiConfID:(NSString *)uiConfId partnerId:(NSString *)partnerId;

+(instancetype)configWithDictionary:(NSDictionary*)configDict;

@property (nonatomic, readonly) NSString *server;
@property (nonatomic, readonly) NSString *partnerId;
    
@property (nonatomic)   NSUInteger audioTrackSelectionDelayMillis;

@property (nonatomic, readonly) NSString *uiConfId;

@property (nonatomic, copy) NSString *localContentId;

@property (nonatomic, copy) NSString *ks;
@property (nonatomic, copy) NSString *entryId;
@property (nonatomic, copy) NSString *advertiserID;
@property (nonatomic) BOOL enableHover;

@property (nonatomic, copy) NSDictionary* supportedMediaFormats;

@property (nonatomic, readonly) KPCacheConfig* cacheConfig;


/// Enables the SDK user to define interface orientation of the player
@property (nonatomic) UIInterfaceOrientationMask supportedInterfaceOrientations;

@property (nonatomic) float cacheSize;

/** Adds flags for the video request
 *
 *  @param NSString The name of the flag
 *  @param NSString The value for the flag
 */
- (void)addConfigKey:(NSString *)key withValue:(NSString *)value;

/** Converts dictionary to JSON and Adds flags to the video request
 *
 *  @param NSString The name of the flag
 *  @param NSDictionary The dictionary for the flag
 */
- (void)addConfigKey:(NSString *)key withDictionary:(NSDictionary *)dictionary;


-(id)configValueForKey:(NSString*)key;

- (NSURL *)videoURL;

- (NSURL *)appendConfiguration:(NSURL *)videoURL;

-(NSMutableArray<NSURLQueryItem*>*)queryItems;

@end
