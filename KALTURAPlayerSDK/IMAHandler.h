//
//  IMAHandler.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/20/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol AdDisplayContainer <NSObject>

- (instancetype)initWithAdContainer:(UIView *)adContainer
                     companionSlots:(NSArray *)companionSlots;

@end

@protocol AdsRequest <NSObject>

- (instancetype)initWithAdTagUrl:(NSString *)adTagUrl
              adDisplayContainer:(id<AdDisplayContainer>)adDisplayContainer
                     userContext:(id)userContext;

@end

@protocol Settings <NSObject>

@property (nonatomic, copy) NSString *language;

@end

@protocol AdsLoader <NSObject>

@property (nonatomic, strong) id delegate;

- (instancetype)initWithSettings:(id<Settings>)settings;
- (void)requestAdsWithRequest:(id<AdsRequest>)request;
- (void)contentComplete;

@end



@protocol AdsRenderingSettings <NSObject>

@property (nonatomic, strong) id webOpenerPresentingController;
@property (nonatomic, strong) id webOpenerDelegate;
@property (nonatomic, assign) int bitrate;

@end

@protocol AVPlayerContentPlayhead <NSObject>

- (instancetype)initWithAVPlayer:(AVPlayer *)player;

@end

@protocol AdsManager <NSObject>

@property (nonatomic, strong) id delegate;

- (void)initializeWithContentPlayhead:(id<AVPlayerContentPlayhead>)contentPlayhead
                 adsRenderingSettings:(id<AdsRenderingSettings>)adsRenderingSettings;
- (void)start;
- (void)pause;
- (void)resume;
- (void)destroy;

@end



@protocol AdsLoadedData <NSObject>

@property (nonatomic, strong) id<AdsManager> adsManager;

@end

@protocol AdError <NSObject>

@property (nonatomic, copy) NSString *message;

@end

@protocol AdLoadingErrorData <NSObject>

@property (nonatomic, strong) id<AdError> adError;

@end

/**
 *  Different event types sent by the IMAAdsManager to its delegate.
 */
typedef NS_ENUM(NSInteger, IMAAdEventType){
    /**
     *  Ad break ready.
     */
    kIMAAdEvent_AD_BREAK_READY,
    /**
     *  Ad break ended (only used for server side ad insertion).
     */
    kIMAAdEvent_AD_BREAK_ENDED,
    /**
     *  Ad break started (only used for server side ad insertion).
     */
    kIMAAdEvent_AD_BREAK_STARTED,
    /**
     *  All ads managed by the ads manager have completed.
     */
    kIMAAdEvent_ALL_ADS_COMPLETED,
    /**
     *  Ad clicked.
     */
    kIMAAdEvent_CLICKED,
    /**
     *  Single ad has finished.
     */
    kIMAAdEvent_COMPLETE,
    /**
     *  Cuepoints changed for VOD stream (only used for dynamic ad insertion).
     */
    kIMAAdEvent_CUEPOINTS_CHANGED,
    /**
     *  First quartile of a linear ad was reached.
     */
    kIMAAdEvent_FIRST_QUARTILE,
    /**
     *  An ad was loaded.
     */
    kIMAAdEvent_LOADED,
    /**
     *  Midpoint of a linear ad was reached.
     */
    kIMAAdEvent_MIDPOINT,
    /**
     *  Ad paused.
     */
    kIMAAdEvent_PAUSE,
    /**
     *  Ad resumed.
     */
    kIMAAdEvent_RESUME,
    /**
     *  Ad has skipped.
     */
    kIMAAdEvent_SKIPPED,
    /**
     *  Ad has started.
     */
    kIMAAdEvent_STARTED,
    /**
     *  Ad tapped.
     */
    kIMAAdEvent_TAPPED,
    /**
     *  Third quartile of a linear ad was reached.
     */
    kIMAAdEvent_THIRD_QUARTILE
};


@protocol AdPodInfo <NSObject>

@property (nonatomic) int adPosition;

@end

@protocol Ad <NSObject>

@property (nonatomic) BOOL isLinear;
@property (nonatomic, copy) NSString *adId;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic, strong) id<AdPodInfo> adPodInfo;

@end

@protocol AdEvent <NSObject>

@property (nonatomic) IMAAdEventType type;
@property (nonatomic, strong) id<Ad> ad;

@end
