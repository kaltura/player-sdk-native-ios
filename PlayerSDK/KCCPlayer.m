//
//  CCKPlayer.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 6/14/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KCCPlayer.h"
#import "KPLog.h"
#import <GoogleCast/GoogleCast.h>

@interface KCCPlayer() {
    NSString* contentID;
    NSTimeInterval* streamPosition;
}

/* A timer to trigger a callback to update the times/slider position. */
@property(weak, nonatomic) NSTimer* updateStreamTimer;

@end

@implementation KCCPlayer

@synthesize delegate = _delegate;
@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize duration = _duration;

- (instancetype)initWithParentView:(UIView *)parentView {
    self = [super init];
    self.chromecastDeviceController = [ChromecastDeviceController sharedInstance];
    self.chromecastDeviceController.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(didReceiveMediaStateChange:)
                                                 name: @"castMediaStatusChange"
                                               object: nil];

    // Start the timer
    if (self.updateStreamTimer) {
        [self.updateStreamTimer invalidate];
        self.updateStreamTimer = nil;
    }
    
    self.updateStreamTimer =
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(updateProgressFromCast:)
                                   userInfo:nil
                                    repeats:YES];
    
    if (self) {
        return self;
    }
    return nil;
}

- (void)changeSubtitleLanguage:(NSString *)languageCode {
    KPLogDebug(@"Enter changeSubtitleLanguage");
}

///@todo remove the timer when view disappears
//- (void)viewWillDisappear:(BOOL)animated {
//    // I think we can safely stop the timer here
//    [self.updateStreamTimer invalidate];
//    self.updateStreamTimer = nil;

- (void)didReceiveMediaStateChange:(NSNotification *)notification {
    KPLogTrace(@"Enter");
    
    switch (self.chromecastDeviceController.playerState) {
        case GCKMediaPlayerStatePlaying:
            if (self.chromecastDeviceController.playerState != GCKMediaPlayerStatePaused) {
                KPLogDebug(@"GCKMediaPlayerStatePlaying");
                [_delegate player:self eventName:PlayKey value:nil];
            }
            break;
        case GCKMediaPlayerStatePaused:
            if (self.chromecastDeviceController.playerState != GCKMediaPlayerStatePlaying) {
                KPLogDebug(@"GCKMediaPlayerStatePaused");
                [_delegate player:self eventName:PauseKey value:nil];
            }
            break;
        case GCKMediaPlayerStateIdle:
            KPLogError(@"didReceiveMediaStateChange: GCKMediaPlayerStateIdle");
            break;

        default:
            KPLogDebug(@"castMediaStatusChanged: %d", self.chromecastDeviceController.playerState);
            break;
    }
}

- (void)updateCurrentTime:(NSTimeInterval)currentTime {
    _currentPlaybackTime = currentTime;
}

- (void)updateProgressFromCast:(NSTimer*)timer {
    KPLogDebug(@"updateProgressFromCast");
    [self updateCurrentTime:self.chromecastDeviceController.streamPosition];
    [_delegate player:self eventName:TimeUpdateKey value:[NSString stringWithFormat:@"%f", _currentPlaybackTime]];
}

- (void)didCompleteLoadWithSessionID:(NSInteger)sessionID {
    KPLogTrace(@"didConnectToDevice");
    [self.delegate player:self
                eventName:DurationChangedKey
                    value:@(self.duration).stringValue];
    [self.delegate player:self
                eventName:LoadedMetaDataKey
                    value:@""];
    [_delegate player:self eventName:CanPlayKey value:nil];
}

- (void)didConnectToDevice:(GCKDevice *)device {
    KPLogTrace(@"didConnectToDevice");
    
    if (self.chromecastDeviceController.mediaInformation) {
        [self.chromecastDeviceController clearPreviousSession];
    }
    
    ///@todo replace null with relevant values
    GCKMediaInformation *mediaInformation =
    [[GCKMediaInformation alloc] initWithContentID: [self.playerSource absoluteString]
                                        streamType: GCKMediaStreamTypeNone
                                    ///@todo get content tipe from avplayer
                                       contentType: self.chromecastDeviceController.mediaInformation.contentType
                                          metadata: self.chromecastDeviceController.mediaInformation.metadata
                                    streamDuration: self.duration
                                        customData: nil];
    [self.chromecastDeviceController setMediaInformation: mediaInformation];
    [self.chromecastDeviceController.mediaControlChannel loadMedia:mediaInformation
                                                          autoplay:YES
                                                      playPosition:_currentPlaybackTime];
    [_delegate player:self eventName:@"chromecastDeviceConnected" value:nil];
}

- (void)didDisconnect {
    KPLogTrace(@"didDisconnect");
    self.chromecastDeviceController.mediaInformation = nil; // Forget media
    [_delegate player:self eventName:@"chromecastDeviceDisConnected" value:nil];
}

- (void)setPlayerSource:(NSURL *)playerSource {
    KPLogInfo(@"playerSource: %@", playerSource);
    
    contentID = [playerSource absoluteString];
}

- (NSURL *)playerSource {
    NSURL *playerSrc = [NSURL URLWithString:contentID];
    KPLogDebug(@"playerSrc: %@", playerSrc);
    
    if (!playerSrc) {
        return nil;
    }
    
    return playerSrc;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
    if (isnan(self.duration) || currentPlaybackTime < self.duration) {
        _currentPlaybackTime = currentPlaybackTime;
        [self.chromecastDeviceController.mediaControlChannel seekToTimeInterval:currentPlaybackTime];
        [_delegate player:self eventName:SeekedKey value:nil];
    }
}

- (NSTimeInterval)currentPlaybackTime {
    return _chromecastDeviceController.streamPosition;;
}

- (void)play {[_delegate player:self eventName:PlayKey value:nil];
    BOOL playing = (self.chromecastDeviceController.playerState == GCKMediaPlayerStatePlaying
                    || self.chromecastDeviceController.playerState == GCKMediaPlayerStateBuffering);
    if (self.chromecastDeviceController.mediaControlChannel &&
        _chromecastDeviceController.deviceManager.applicationConnectionState == GCKConnectionStateConnected &&
        !playing) {
        [self.chromecastDeviceController.mediaControlChannel play];
    }
}

- (void)pause {
    BOOL paused = (self.chromecastDeviceController.playerState == GCKMediaPlayerStatePaused
                    || self.chromecastDeviceController.playerState == GCKMediaPlayerStateUnknown);
    if (self.chromecastDeviceController.mediaControlChannel &&
        _chromecastDeviceController.deviceManager.applicationConnectionState == GCKConnectionStateConnected &&
        !paused) {
        [self.chromecastDeviceController.mediaControlChannel pause];
    }
}

- (void)removePlayer {
    [self pause];
    [self.chromecastDeviceController clearPreviousSession];
    self.chromecastDeviceController = nil;
    self.delegate = nil;
}

- (BOOL)isKPlayer {
    return nil;
}

/// @todo check that dealloc was called
- (void)dealloc {
    KPLogInfo(@"Dealloc");
}

@end
