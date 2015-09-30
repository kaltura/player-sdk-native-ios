//
//  CCKPlayer.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 6/14/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KCCPlayer.h"
#import "KPLog.h"
#import "/Users/elizasapir/Desktop/GitRepositories/player-sdk-native-ios/PlayerSDK/GoogleCast.framework/Versions/A/Headers/GoogleCast.h"

@interface KCCPlayer() {
    NSString* contentID;
    NSTimeInterval* streamPosition;
    BOOL isPlaying;
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

    // Start the timer
    if (self.updateStreamTimer) {
        [self.updateStreamTimer invalidate];
        self.updateStreamTimer = nil;
    }
    
    self.updateStreamTimer =
    [NSTimer scheduledTimerWithTimeInterval:0.2
                                     target:self
                                   selector:@selector(updateProgressFromCast:)
                                   userInfo:nil
                                    repeats:YES];
    isPlaying = NO;
    
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

- (void)updateCurrentTime:(NSTimeInterval)currentTime {
    _currentPlaybackTime = currentTime;
}

- (void)updateProgressFromCast:(NSTimer*)timer {
    if (self.chromecastDeviceController.playerState == GCKMediaPlayerStatePlaying) {
        KPLogDebug(@"updateProgressFromCast");
        [self updateCurrentTime:self.chromecastDeviceController.streamPosition];
        [_delegate player:self
                eventName:TimeUpdateKey
                    value:[NSString stringWithFormat:@"%f", _currentPlaybackTime]];
        NSLog(@"%f", _currentPlaybackTime);
    }
}

- (void)didCompleteLoadWithSessionID:(NSInteger)sessionID {
    KPLogTrace(@"didConnectToDevice");
    [self.delegate player:self
                eventName:DurationChangedKey
                    value:@(self.duration).stringValue];
    [self.delegate player:self
                eventName:LoadedMetaDataKey
                    value:@""];
    [self.delegate player:self eventName:CanPlayKey value:nil];
}

- (void)castConnectingToDevice {
    KPLogTrace(@"castConnectingToDevice");
    [_delegate player:self
            eventName:@"chromecastShowConnectingMsg"
                value:nil];
}

- (void)didUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel {
    KPLogTrace(@"didUpdateStatus");
    
    switch (self.chromecastDeviceController.playerState) {
        case GCKMediaPlayerStatePlaying:
            if (!isPlaying) {
                KPLogDebug(@"GCKMediaPlayerStatePlaying");
                [_delegate player:self eventName:PlayKey value:nil];
                isPlaying = YES;
            }
            break;
        case GCKMediaPlayerStatePaused:
            if (isPlaying) {
                KPLogDebug(@"GCKMediaPlayerStatePaused");
                [_delegate player:self eventName:PauseKey value:nil];
                isPlaying = NO;
            }
            break;
        case GCKMediaPlayerStateIdle:
            [self didReceiveIdleReason];
            KPLogError(@"didReceiveMediaStateChange: GCKMediaPlayerStateIdle");
            break;
            
        default:
            KPLogDebug(@"castMediaStatusChanged: %d", self.chromecastDeviceController.playerState);
            break;
    }
}

- (void)didReceiveIdleReason {
    KPLogTrace(@"didReceiveIdleReason");
    
    switch (self.chromecastDeviceController.idleReason) {
        case GCKMediaPlayerIdleReasonNone:
        case GCKMediaPlayerIdleReasonFinished:
            if (round(_currentPlaybackTime) == round(_duration)) {
                ///@todo improve 'contentCompleted' to send "ended" event
                [_delegate player:self eventName:EndedKey value:nil];
//                [_delegate contentCompleted:self];
                [self loadMedia];
            }
            break;
            
        default:
            break;
    }
}

- (void)didConnectToDevice:(GCKDevice *)device {
    KPLogTrace(@"didConnectToDevice");
    
    if (self.chromecastDeviceController.mediaInformation) {
        [self.chromecastDeviceController clearPreviousSession];
    }
    
    [self loadMedia];
    [_delegate player:self eventName:@"chromecastDeviceConnected" value:nil];
}

/**
 *  Creates and loads playback of a new media item
 */
- (void)loadMedia {
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
                                                          autoplay:NO
                                                      playPosition:_currentPlaybackTime];
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

/**
 *  Seeks to a new position within the current media item
 */
- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
    if (isnan(self.duration) || currentPlaybackTime < self.duration) {
        _currentPlaybackTime = currentPlaybackTime;
        [self.chromecastDeviceController.mediaControlChannel seekToTimeInterval:currentPlaybackTime];
        [_delegate player:self eventName:SeekedKey value:nil];
    }
}

/**
 *  Begins (or resumes) playback of the current media item
 */
- (void)play {
    BOOL playing = (self.chromecastDeviceController.playerState == GCKMediaPlayerStatePlaying
                    || self.chromecastDeviceController.playerState == GCKMediaPlayerStateBuffering);
    if (self.chromecastDeviceController.mediaControlChannel &&
        _chromecastDeviceController.deviceManager.applicationConnectionState == GCKConnectionStateConnected &&
        !playing) {
        NSTimeInterval currTime = _currentPlaybackTime;
        [_chromecastDeviceController clearPreviousSession];
        [self.chromecastDeviceController.mediaControlChannel play];
        
        if ( (NSInteger)currTime > 0 && round(currTime) <= round(_duration)) {
            [self setCurrentPlaybackTime:currTime];
        }
    }
}

/**
 *  Set player's position to the begining
 */
- (void)replay {
    [self setCurrentPlaybackTime:0];
}

/**
 *  Pauses playback of the current media item
 */
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
