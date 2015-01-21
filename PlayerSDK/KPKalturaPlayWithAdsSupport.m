//
//  KPKalturaPlayWithAdsSupport.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 12/4/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//



#import "KPKalturaPlayWithAdsSupport.h"
#import "NSString+Utilities.h"
#import "NSMutableDictionary+AdSupport.h"

@interface KPKalturaPlayWithAdsSupport() {
    void(^_adEventUpdateBlock)(NSDictionary *adEventParams);
}
@property (nonatomic, copy) NSMutableDictionary *adEventParams;
@end


@implementation KPKalturaPlayWithAdsSupport

- (instancetype)initWithFrame:(CGRect)frame forView:(UIView *)parentView {
    if (!self) {
        self = [super initWithFrame:frame forView:parentView];
        
        self.contentPlayer = [[AVPlayer alloc] init];
        
        // Create a player layer for the player.
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.contentPlayer];
        
        // Size, position, and display the AVPlayer.
        playerLayer.frame = self.view.layer.bounds;
        [self.view.layer addSublayer:playerLayer];
    }
    return self;
}


- (NSMutableDictionary *)adEventParams {
    if (!_adEventParams) {
        _adEventParams = [NSMutableDictionary new];
    }
    return _adEventParams;
}


// Create ads rendering settings to tell the SDK to use the in-app browser.
- (IMAAdsRenderingSettings *)adsRenderingSettings {
    if (!_adsRenderingSettings) {
        _adsRenderingSettings = [IMAAdsRenderingSettings new];
        _adsRenderingSettings.webOpenerPresentingController = self;
    }
    return _adsRenderingSettings;
}


// Create a content playhead so the SDK can track our content for VMAP and ad rules.
- (IMAAVPlayerContentPlayhead *)contentPlayhead {
    if (!_contentPlayhead) {
        _contentPlayhead = [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:self.contentPlayer];
    }
    return _contentPlayhead;
}

// Create our AdDisplayContainer. Initialize it with our videoView as the container. This
- (IMAAdDisplayContainer *)adDisplayContainer {
    if (!_adDisplayContainer) {
        _adDisplayContainer = [[IMAAdDisplayContainer alloc] initWithAdContainer:self.view.superview
                                                                  companionSlots:nil];
    }
    return _adDisplayContainer;
}

- (IMAAdsLoader *)adsLoader {
    if (!_adsLoader) {
        _adsLoader = [[IMAAdsLoader alloc] initWithSettings:nil];
        _adsLoader.delegate = self;
    }
    return _adsLoader;
}

- (void)showAdAtURL:(NSString *)adTagUrl updateAdEvents:(void (^)(NSDictionary *))updateBlock {
    _adEventUpdateBlock = [updateBlock copy];
    IMAAdsRequest *request = [[IMAAdsRequest alloc] initWithAdTagUrl:adTagUrl
                                                  adDisplayContainer:self.adDisplayContainer
                                                         userContext:nil];
    
    [self.adsLoader requestAdsWithRequest:request];
}

#pragma mark AdsLoader Delegates

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
    // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
    self.adsManager = adsLoadedData.adsManager;
    self.adsManager.delegate = self;
    

    //[self createAdsRenderingSettings];
    // Create a content playhead so the SDK can track our content for VMAP and ad rules.
    //[self createContentPlayhead];
    // Initialize the ads manager.
    [self.adsManager initializeWithContentPlayhead:self.contentPlayhead
                              adsRenderingSettings:self.adsRenderingSettings];
    if (_adEventUpdateBlock) {
        _adEventUpdateBlock(AdLoadedEventKey.nullVal);
    }
}

- (void)adsLoader:(IMAAdsLoader *)loader failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData {
    // Something went wrong loading ads. Log the error and play the content.
    NSLog(@"Error loading ads: %@", adErrorData.adError.message);
    [self play];
}

#pragma mark AdsManager Delegates

- (void)adsManager:(IMAAdsManager *)adsManager
 didReceiveAdEvent:(IMAAdEvent *)event {
    // When the SDK notified us that ads have been loaded, play them.
    NSDictionary *eventParams = nil;
    switch (event.type) {
        case kIMAAdEvent_LOADED:
            [adsManager start];
//            self.adEventParams.isLinear = event.ad.isLinear;
//            self.adEventParams.adID = event.ad.adId;
//            self.adEventParams.adSystem = @"null";
//            self.adEventParams.adPosition = event.ad.adPodInfo.adPosition;
//            eventParams = self.adEventParams.toJSON.adLoaded;
            break;
        case kIMAAdEvent_STARTED:
            self.adEventParams.isLinear = event.ad.isLinear;
            self.adEventParams.adID = event.ad.adId;
            self.adEventParams.adSystem = @"null";
            self.adEventParams.adPosition = event.ad.adPodInfo.adPosition;
            //self.adEventParams.context = @"null";
            self.adEventParams.duration = event.ad.duration;
            eventParams = self.adEventParams.toJSON.adStart;
            break;
        case kIMAAdEvent_COMPLETE:
            self.adEventParams.adID = event.ad.adId;
            eventParams = self.adEventParams.toJSON.adCompleted;
            break;
        case kIMAAdEvent_ALL_ADS_COMPLETED:
            eventParams = AllAdsCompletedKey.nullVal;
            break;
//        case kIMAAdEvent_PAUSE:
//            eventParams = ContentPauseRequestedKey.nullVal;
//            break;
//        case kIMAAdEvent_RESUME:
//            eventParams = ContentResumeRequestedKey.nullVal;
//            break;
        case kIMAAdEvent_FIRST_QUARTILE:
            eventParams = FirstQuartileKey.nullVal;
            break;
        case kIMAAdEvent_MIDPOINT:
            eventParams = MidPointKey.nullVal;
            break;
        case kIMAAdEvent_THIRD_QUARTILE:
            eventParams = ThirdQuartileKey.nullVal;
            break;
        default:
            break;
    }
    self.adEventParams = nil;
    if (_adEventUpdateBlock) {
        _adEventUpdateBlock(eventParams);
    }
//    if (event.type == kIMAAdEvent_COMPLETE) {
//        _adEventUpdateBlock = nil;
//    }
    eventParams = nil;
}

- (void)adsManager:(IMAAdsManager *)adsManager
 didReceiveAdError:(IMAAdError *)error {
    // Something went wrong with the ads manager after ads were loaded. Log the error and play the
    // content.
    NSLog(@"AdsManager error: %@", error.message);
    [self play];
}

- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager {
    // The SDK is going to play ads, so pause the content.
    [self pause];
    if (_adEventUpdateBlock) {
        _adEventUpdateBlock(ContentPauseRequestedKey.nullVal);
    }
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
    // The SDK is done playing ads (at least for now), so resume the content.
    [self play];
    if (_adEventUpdateBlock) {
        _adEventUpdateBlock(ContentResumeRequestedKey.nullVal);
    }
}

- (void)adDidProgressToTime:(NSTimeInterval)mediaTime totalTime:(NSTimeInterval)totalTime {
//    [self triggerKPlayerEvents: @"timeupdate"
//                     withValue: @{@"timeupdate": [NSString stringWithFormat:@"%f", mediaTime]}];
    if (_adEventUpdateBlock) {
        NSMutableDictionary *timeParams = [NSMutableDictionary new];
        timeParams.time = mediaTime;
        timeParams.duration = totalTime;
        timeParams.remain = totalTime - mediaTime;
        _adEventUpdateBlock(timeParams.toJSON.adRemainingTimeChange);
        timeParams = nil;
    }

}

@end
