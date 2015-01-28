//
//  KPIMAPlayerViewController.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 1/26/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NSMutableDictionary+AdSupport.h"
#import "IMAAdsLoader.h"
#import "IMAAVPlayerContentPlayhead.h"

@protocol KPIMAAdsPlayerDatasource <IMAContentPlayhead>

@property (nonatomic, assign, readonly) CGFloat adPlayerHeight;

@end

@interface KPIMAPlayerViewController : UIViewController <IMAAdsLoaderDelegate,
IMAAdsManagerDelegate>

/// Content video player.
@property(nonatomic, strong) AVPlayer *contentPlayer;

- (instancetype)initWithParent:(UIViewController *)parentController;
- (void)loadIMAAd:(NSString *)adLink eventsListener:(void(^)(NSDictionary *adEventParams))adListener;
- (void)destroy;

// SDK
/// Entry point for the SDK. Used to make ad requests.
@property(nonatomic, strong) IMAAdsLoader *adsLoader;
// Container which lets the SDK know where to render ads.
@property(nonatomic, strong) IMAAdDisplayContainer *adDisplayContainer;
// Rendering settings for ads.
@property(nonatomic, strong) IMAAdsRenderingSettings *adsRenderingSettings;

/// Main point of interaction with the SDK. Created by the SDK as the result of an ad request.
@property(nonatomic, strong) IMAAdsManager *adsManager;
@end
