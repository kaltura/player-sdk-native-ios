//
//  KPMoviePlayerController.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 7/2/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPController.h"
#import "KPController_Private.h"
#import "DeviceParamsHandler.h"

@implementation KPController
@synthesize currentPlaybackRate;
@synthesize currentPlaybackTime;

NSString *const DoPlayKey = @"doPlay";
NSString *const DoPauseKey = @"doPause";
NSString *const DoSeekKey = @"doSeek";
NSString *const DoReplayKey = @"doReplay";
NSString *const KMediaPlaybackStateKey = @"mediaPlaybackState";
NSString *const KMediaSource = @"KMediaSource";

NSString * const KPMediaPlaybackStateDidChangeNotification = @"KPMediaPlaybackStateDidChangeNotification";

#define KP_CONTROLS_WEBVIEW  SYSTEM_VERSION_EQUAL_TO(@"7") ? @"KPControlsUIWebview" : @"KPControlsWKWebview"

NSString *sendNotification(NSString *notification, NSString *params) {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.sendNotification(\"%@\" ,%@);", notification, params];
}

NSString *setKDPAttribute(NSString *pluginName, NSString *propertyName, NSString *value) {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.setKDPAttribute('%@','%@', %@);", pluginName, propertyName, value];
}

NSString *triggerEvent(NSString *event, NSString *value) {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.trigger('%@', '%@')", event, value];
}

NSString *triggerEventWithJSON(NSString *event, NSString *jsonString) {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.trigger('%@', %@)", event, jsonString];
}

NSString *asyncEvaluate(NSString *expression, NSString *evaluateID) {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.asyncEvaluate(\"%@\", \"%@\");", expression, evaluateID];
}

NSString *showChromecastComponent(BOOL show) {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.showChromecastComponent(\"%@\");", @(show).stringValue];
}

- (void)setPlaybackState:(KPMediaPlaybackState)newState {
    _playbackState = newState;
}

- (void)setLoadState:(KPMediaLoadState)newState {
    _loadState = newState;
}

///@todo prepareToPlay
- (void)prepareToPlay {
    
}

- (void)play {
    if ([_delegate respondsToSelector:@selector(sendKPNotification:withParams:)]) {
        [_delegate sendKPNotification:DoPlayKey withParams:nil];
    }
}

- (void)pause {
    if ([_delegate respondsToSelector:@selector(sendKPNotification:withParams:)]) {
        [_delegate sendKPNotification:DoPauseKey withParams:nil];
    }
}

- (void)seek:(NSTimeInterval)playbackTime {
    if ([_delegate respondsToSelector:@selector(sendKPNotification:withParams:)]) {
        [_delegate sendKPNotification:DoSeekKey withParams:[@(playbackTime) stringValue]];
    }
}


- (void)replay {
    if ([_delegate respondsToSelector:@selector(sendKPNotification:withParams:)]) {
        [_delegate sendKPNotification:DoReplayKey withParams:nil];
    }
}

///@todo setCurrentPlaybackRate
- (void)setCurrentPlaybackRate:(float)currentPlaybackRate {

}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currPlaybackTime {
    
    if (currPlaybackTime == 0) {
        currPlaybackTime = 0.01;
    }
    
    if ([_delegate respondsToSelector:@selector(sendKPNotification:withParams:)]) {
        [_delegate sendKPNotification:DoSeekKey withParams:[@(currPlaybackTime) stringValue]];
    }
}

///@todo setsource refactor
- (void)setContentURL:(NSURL *)contentURL {
    if ([_delegate respondsToSelector:@selector(sendKPNotification:withParams:)]) {
        [_delegate sendKPNotification:@"changeMedia" withParams:[NSString stringWithFormat:@"{\"mediaProxy\": {\"sources\":[{\"src\":\"%@\", \"type\":\"%@\"}]}}", [contentURL absoluteString],@"application/vnd.apple.mpegurl"]];
    }
}

- (NSTimeInterval)duration {
    return _delegate.duration;
}

- (NSTimeInterval)currentPlaybackTime {
    return _delegate.currentPlaybackTime;
}

- (BOOL)isPreparedToPlay {
    return nil;
}

- (float)volume {
    return _delegate.volume;
}

- (void)setVolume:(float)value {
    if ([_delegate respondsToSelector:@selector(setVolume:)]) {
        [_delegate setVolume:value];
    }
}

- (BOOL)isMuted {
    return _delegate.mute;
}

- (void)setMute:(BOOL)isMute {
    if ([_delegate respondsToSelector:@selector(setVolume:)]) {
        [_delegate setMute:isMute];
    }
}

+ (id<KPController>)defaultControlsViewWithFrame:(CGRect)frame {
    return (id<KPController>)[[NSClassFromString(@"KPControlsUIWebview") alloc] initWithFrame:frame];
}

@end
