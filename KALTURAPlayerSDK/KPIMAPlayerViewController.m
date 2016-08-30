//
//  KPIMAPlayerViewController.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 1/26/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPIMAPlayerViewController.h"
#import "NSString+Utilities.h"
#import "KPLog.h"
#import "IMAHandler.h"

@interface KPIMAPlayerViewController ()

/// Contains the params for the logic layer
@property (nonatomic, copy) NSMutableDictionary *adEventParams;

/// Content video player.
@property(nonatomic, strong) AVPlayer *contentPlayer;


// SDK
/// Entry point for the SDK. Used to make ad requests.
@property(nonatomic, strong) id<AdsLoader> adsLoader;
// Container which lets the SDK know where to render ads.
@property(nonatomic, strong) id<AdDisplayContainer> adDisplayContainer;
// Rendering settings for ads.
@property(nonatomic, strong) id<AdsRenderingSettings> adsRenderingSettings;

/// Main point of interaction with the SDK. Created by the SDK as the result of an ad request.
@property(nonatomic, strong) id<AdsManager> adsManager;

@property (nonatomic, strong) id<AVPlayerContentPlayhead> playhead;
@end

@implementation KPIMAPlayerViewController

#pragma mark Public Methods

- (instancetype)init {
    
    if (!NSClassFromString(@"IMAAdsRequest")) {
        return nil;
    }
    
    self = [super init];
    
    if (self) {
        return self;
    }
    
    return nil;
}

- (void)loadIMAAd:(NSString *)adLink withContentPlayer:(AVPlayer *)contentPlayer {
    
    // Load AVPlayer with path to our content.
    self.contentPlayer = contentPlayer;
    id<AdsRequest> request = [[NSClassFromString(@"IMAAdsRequest") alloc] initWithAdTagUrl:adLink
                                                                        adDisplayContainer:self.adDisplayContainer
                                                                               userContext:nil];
    
    [self.adsLoader requestAdsWithRequest:request];
}

- (void)contentCompleted {
// Notify IMA SDK when content is done for post-rolls.
    [self.adsLoader contentComplete];
}

- (void)removeIMAPlayer {
    [_adEventParams removeAllObjects];
    _adEventParams = nil;
    _adsLoader.delegate = nil;
    _adsLoader = nil;
    _adDisplayContainer = nil;
    _adsRenderingSettings = nil;
    _contentPlayer = nil;
    _playhead = nil;
    _contentPlayer = nil;
    _datasource = nil;
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    [self.adsManager pause];
    [self.adsManager destroy];
}


#pragma mark View methods
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
    self.view.frame = (CGRect){0, 0, self.view.frame.size.width, _adPlayerHeight};
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark Lazy Initialization
- (NSMutableDictionary *)adEventParams {
    if (!_adEventParams) {
        _adEventParams = [NSMutableDictionary new];
    }
    return _adEventParams;
}


// Create ads rendering settings to tell the SDK to use the in-app browser.
- (id<AdsRenderingSettings>)adsRenderingSettings {
    if (!_adsRenderingSettings) {
        _adsRenderingSettings = [NSClassFromString(@"IMAAdsRenderingSettings") new];
        _adsRenderingSettings.webOpenerPresentingController = self;
        _adsRenderingSettings.webOpenerDelegate = _datasource;
    }
    return _adsRenderingSettings;
}


// Create our AdDisplayContainer. Initialize it with our videoView as the container. This
- (id<AdDisplayContainer>)adDisplayContainer {
    if (!_adDisplayContainer) {
        _adDisplayContainer = [[NSClassFromString(@"IMAAdDisplayContainer") alloc] initWithAdContainer:self.view
                                                                                        companionSlots:nil];
    }
    return _adDisplayContainer;
}

- (id<AdsLoader>)adsLoader {
    if (!_adsLoader) {
        id<Settings> settings = nil;
        if (![_locale isKindOfClass:[NSNull class]] && _locale.length) {
            settings = [NSClassFromString(@"IMASettings") new];
            settings.language = _locale;
        }
        _adsLoader = [(id<AdsLoader>)[NSClassFromString(@"IMAAdsLoader") alloc] initWithSettings:settings];
        _adsLoader.delegate = self;
    }
    return _adsLoader;
}

- (id<AVPlayerContentPlayhead>)playhead {
    if (!_playhead) {
        _playhead = [[NSClassFromString(@"IMAAVPlayerContentPlayhead") alloc] initWithAVPlayer:self.contentPlayer];
    }
    return _playhead;
}



#pragma mark IMAAdsLoaderDelegate
- (void)adsLoader:(id<AdsLoader>)loader adsLoadedWithData:(id<AdsLoadedData>)adsLoadedData {
    // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
    self.adsManager = adsLoadedData.adsManager;
    self.adsManager.delegate = self;
    // Initialize the ads manager.
    
    [self.adsManager initializeWithAdsRenderingSettings: self.adsRenderingSettings];
    
    NSDictionary *eventParams = AdLoadedEventKey.nullVal;
    [self.delegate player:nil
                eventName:eventParams.allKeys.firstObject
                     JSON:eventParams.allValues.firstObject];
}

- (void)adsLoader:(id<AdsLoader>)loader failedWithErrorData:(id<AdLoadingErrorData>)adErrorData {
    // Something went wrong loading ads. Log the error and play the content.
    KPLogError(@"Error loading ads: %@", adErrorData.adError.message);
    
     NSDictionary *eventParams = AdsLoadErrorKey.nullVal;
    [self.delegate player:nil
                eventName:eventParams.allKeys.firstObject
                     JSON:eventParams.allValues.firstObject];
}

- (void)adsManager:(id<AdsManager>)adsManager
 didReceiveAdError:(id<AdError>)error {
    // Something went wrong with the ads manager after ads were loaded. Log the error and play the
    // content.
    NSDictionary *eventParams = AdsLoadErrorKey.nullVal;
    [self.delegate player:nil
                eventName:eventParams.allKeys.firstObject
                     JSON:eventParams.allValues.firstObject];
    
    NSLog(@"AdsManager error: %@", error.message);
    [self.contentPlayer play];
}

#pragma mark AdsManager Delegates
- (void)adsManager:(id<AdsManager>)adsManager
 didReceiveAdEvent:(id<AdEvent>)event {
    // When the SDK notified us that ads have been loaded, play them.
    NSDictionary *eventParams = nil;
    switch (event.type) {
        case kIMAAdEvent_LOADED:
            [adsManager start];
            self.adEventParams.isLinear = event.ad.isLinear;
            self.adEventParams.adID = event.ad.adId;
            self.adEventParams.adSystem = @"null";
            self.adEventParams.adPosition = event.ad.adPodInfo.adPosition;
            eventParams = self.adEventParams.toJSON.adLoaded;
            
            break;
        case kIMAAdEvent_STARTED:
            self.view.hidden = NO;
            self.adEventParams.duration = event.ad.duration;
            eventParams = self.adEventParams.toJSON.adStart;
            break;
        case kIMAAdEvent_COMPLETE:
            self.adEventParams.adID = event.ad.adId;
            eventParams = self.adEventParams.toJSON.adCompleted;
            self.view.hidden = YES;
            break;
        case kIMAAdEvent_ALL_ADS_COMPLETED:
            eventParams = AllAdsCompletedKey.nullVal;
            break;
        case kIMAAdEvent_FIRST_QUARTILE:
            eventParams = FirstQuartileKey.nullVal;
            break;
        case kIMAAdEvent_MIDPOINT:
            eventParams = MidPointKey.nullVal;
            break;
        case kIMAAdEvent_THIRD_QUARTILE:
            eventParams = ThirdQuartileKey.nullVal;
            break;
        case kIMAAdEvent_TAPPED:
            break;
        case kIMAAdEvent_CLICKED:
            self.adEventParams.isLinear = event.ad.isLinear;
            eventParams = self.adEventParams.toJSON.adClicked;
            break;
        case kIMAAdEvent_SKIPPED:
            self.adEventParams.isLinear = event.ad.isLinear;
            eventParams = self.adEventParams.toJSON.adSkipped;
            break;
        default:
            break;
    }
    self.adEventParams = nil;
    
    if (eventParams) {
        [self.delegate player:nil
                    eventName:eventParams.allKeys.firstObject
                         JSON:eventParams.allValues.firstObject];
        eventParams = nil;
    }
}

- (void)adsManagerDidRequestContentPause:(id<AdsManager>)adsManager {
    // The SDK is going to play ads, so pause the content.
    [self.contentPlayer pause];
    NSDictionary *eventParams = ContentPauseRequestedKey.nullVal;
    [self.delegate player:nil
                eventName:eventParams.allKeys.firstObject
                     JSON:eventParams.allValues.firstObject];
}

- (void)adsManagerDidRequestContentResume:(id<AdsManager>)adsManager {
    // The SDK is done playing ads (at least for now), so resume the content.
    [self.contentPlayer play];
    NSDictionary *eventParams = ContentResumeRequestedKey.nullVal;
    [self.delegate player:nil
                eventName:eventParams.allKeys.firstObject
                     JSON:eventParams.allValues.firstObject];
}

- (void)adDidProgressToTime:(NSTimeInterval)mediaTime totalTime:(NSTimeInterval)totalTime {
    NSMutableDictionary *timeParams = [NSMutableDictionary new];
    timeParams.time = mediaTime;
    timeParams.duration = totalTime;
    timeParams.remain = totalTime - mediaTime;
    NSDictionary *eventParams = timeParams.toJSON.adRemainingTimeChange;
    [self.delegate player:nil
                eventName:eventParams.allKeys.firstObject
                     JSON:eventParams.allValues.firstObject];
}

- (void)dealloc {
    KPLogInfo(@"Dealloc");
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)pause {
    if (_adsManager) {
        [_adsManager pause];
    }
}

- (void)resume {
    if (_adsManager) {
        [_adsManager resume];
    }
}

@end

