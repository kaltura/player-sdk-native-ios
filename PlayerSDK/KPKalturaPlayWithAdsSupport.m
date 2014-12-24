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

- (void)showAdAtURL:(NSString *)adTagUrl {
    [self setupAdsLoader];
    [self setUpAdDisplayContainer];
    IMAAdsRequest *request =
    [[IMAAdsRequest alloc] initWithAdTagUrl:adTagUrl
                         adDisplayContainer:self.adDisplayContainer
                                userContext:nil];
    
    [self.adsLoader requestAdsWithRequest:request];
}

- (void)setupAdsLoader {
    self.adsLoader = [[IMAAdsLoader alloc] initWithSettings:nil];
    self.adsLoader.delegate = self;
}

- (void)setUpAdDisplayContainer {
    // Create our AdDisplayContainer. Initialize it with our videoView as the container. This
    // will result in ads being displayed over our content video.
    self.adDisplayContainer =
    [[IMAAdDisplayContainer alloc] initWithAdContainer:self.view.superview companionSlots:nil];
}

- (void)createAdsRenderingSettings {
    self.adsRenderingSettings = [[IMAAdsRenderingSettings alloc] init];
    self.adsRenderingSettings.webOpenerPresentingController = self;
}

- (void)createContentPlayhead {
    self.contentPlayhead = [[IMAAVPlayerContentPlayhead alloc] initWithAVPlayer:self.contentPlayer];
}

#pragma mark AdsLoader Delegates

- (void)adsLoader:(IMAAdsLoader *)loader adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData {
    // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
    self.adsManager = adsLoadedData.adsManager;
    self.adsManager.delegate = self;
    // Create ads rendering settings to tell the SDK to use the in-app browser.
    [self createAdsRenderingSettings];
    // Create a content playhead so the SDK can track our content for VMAP and ad rules.
    [self createContentPlayhead];
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
