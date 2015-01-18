//
//  KPKalturaPlayWithAdsSupport.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 12/4/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPKalturaPlayWithAdsSupport.h"

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

- (void)showAdAtURL:(NSString *)adTagUrl {
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
    
    // Initialize the ads manager.
    [self.adsManager initializeWithContentPlayhead:self.contentPlayhead
                              adsRenderingSettings:self.adsRenderingSettings];
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
    if (event.type == kIMAAdEvent_LOADED) {
        [adsManager start];
    }
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
}

- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager {
    // The SDK is done playing ads (at least for now), so resume the content.
    [self play];
}

@end
