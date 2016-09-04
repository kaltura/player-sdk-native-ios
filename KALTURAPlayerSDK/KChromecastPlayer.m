//
//  KChromecastPlayer.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 02/06/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KChromecastPlayer.h"
#import "NSString+Utilities.h"
#import "KPLog.h"

typedef NS_ENUM(NSInteger, PlayerState) {
    PlayerStatePause,
    PlayerStatePlaying,
    PlayerStateSeeking
};

typedef NS_ENUM(NSInteger, PlayerDelegateMethod) {
    updateProgress,
    castPlayerState,
    readyToPlay
};

@interface KChromecastPlayer()
@property (nonatomic, strong) id<KPGCMediaControlChannel> mediaChannel;
@property (nonatomic, strong) id<KPGCMediaInformation> currentMediaInformation;
@property (nonatomic, strong) NSMutableSet *observers;
@property (nonatomic) PlayerState playerState;
@property (nonatomic) BOOL isEnded;
@property (nonatomic) BOOL isChangeMedia;
@property (nonatomic) BOOL wasReadyToplay;
@end


@implementation KChromecastPlayer

@synthesize observers = _observers, mediaStatus = _mediaStatus;

- (instancetype)initWithMediaChannel:(id<KPGCMediaControlChannel>)mediaChannel andCastParams:(NSArray *)castParams {
    self = [super init];
    if (self) {
        _mediaChannel = mediaChannel;
        _mediaChannel.delegate = self;
        
        if ([castParams count] > 0) {
            _mediaSrc = [castParams firstObject];
            KPLogTrace(@"mediaSrc::%@", _mediaSrc);
        }

        return self;
    }
    return nil;
}

- (void)setMediaSrc:(NSString *)mediaSrc {
    if (_mediaSrc != nil) {
        _isChangeMedia = YES;
        _mediaSrc = mediaSrc;
    } else {
        _mediaSrc = mediaSrc;
    }
}

- (void)setVideoUrl:(NSString *)videoUrl startPosition:(NSTimeInterval)startPosition autoPlay:(BOOL)isAutoPlay {
    KPLogDebug(@"Enter setVideoUrl");
    
    if (!videoUrl && _mediaSrc) {
        videoUrl = _mediaSrc;
    }
    
    KPLogTrace(@"Video Url: ", videoUrl);
    
    id<KPGCMediaInformation> mediaInformation = [[NSClassFromString(@"GCKMediaInformation") alloc] initWithContentID:videoUrl
                                                                                                          streamType:0                                      contentType:videoUrl.mimeType                              metadata:nil                    streamDuration:0                             customData:nil];
    
    
    // Cast the video.
    if (_currentMediaInformation.contentID != mediaInformation.contentID || _isEnded) {
        _currentMediaInformation = mediaInformation;
        [self stop];
        [_mediaChannel loadMedia:mediaInformation autoplay:isAutoPlay playPosition:startPosition];
    }
    
    KPLogDebug(@"Exit setVideoUrl");
}

- (void)play {
    if ((_isEnded || _isChangeMedia) && _playerState != PlayerStatePlaying) {
        [self setVideoUrl:_mediaSrc startPosition:0 autoPlay:YES];
        _isEnded = NO;
        _isChangeMedia = NO;
        return;
    }
    if (_playerState == PlayerStatePause) {
        [_mediaChannel play];
    }
}

- (void)pause {
    if (_playerState == PlayerStatePlaying) {
        [_mediaChannel pause];
    }
}

- (NSInteger)stop {
    return [_mediaChannel stop];
}

- (NSInteger)seekToTimeInterval:(NSTimeInterval)position {
    _playerState = PlayerStateSeeking;
    return [_mediaChannel seekToTimeInterval:position];
}

- (NSInteger)setStreamVolume:(float)volume {
    return [_mediaChannel setStreamVolume:volume];
}

- (NSInteger)setStreamMuted:(BOOL)muted {
    return [_mediaChannel setStreamMuted:muted];
}

- (NSTimeInterval)currentTime {
    return _mediaChannel.approximateStreamPosition;
}

- (BOOL)wasReadyToplay {
    return _wasReadyToplay;
}

- (NSTimeInterval)duration {
    return _mediaChannel.mediaStatus.mediaInformation.streamDuration;
}

- (void)setCurrentTime:(NSTimeInterval)currentTime {
    [_mediaChannel seekToTimeInterval:currentTime];
}

- (void)startUpdateTime {
    if (_mediaChannel.mediaStatus.playerState == KPGCMediaPlayerStatePlaying) {
        [self setDelegate:updateProgress withValue:[NSNumber numberWithDouble:_mediaChannel.approximateStreamPosition]];
        [self performSelector:@selector(startUpdateTime) withObject:nil afterDelay:0.2];
    }
}

- (void)stopUpdateTime {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startUpdateTime) object:nil];
}

- (void)mediaControlChannelDidUpdateStatus:(id<KPGCMediaControlChannel>)mediaControlChannel {
    switch ([[mediaControlChannel mediaStatus] playerState]) {
        case KPGCMediaPlayerStateUnknown:
            break;
        case KPGCMediaPlayerStateIdle:
            if ([[mediaControlChannel mediaStatus] idleReason] == KPGCMediaPlayerIdleReasonFinished) {
                _isEnded = YES;
                _playerState = PlayerStatePause;
                [self setDelegate:castPlayerState withValue:@"ended"];
            }
            break;
        case KPGCMediaPlayerStatePlaying:
            if (_playerState == PlayerStateSeeking) {
                [self setDelegate:castPlayerState withValue:@"seeked"];
            } else {
                [self setDelegate:castPlayerState withValue:@"play"];
            }
            _playerState = PlayerStatePlaying;
            [self startUpdateTime];
            break;
        case KPGCMediaPlayerStatePaused:
            if (_playerState == PlayerStateSeeking) {
                [self setDelegate:castPlayerState withValue:@"seeked"];
            } else {
                [self setDelegate:castPlayerState withValue:@"pause"];
            }
            _playerState = PlayerStatePause;
            [self stopUpdateTime];
            break;
        case KPGCMediaPlayerStateBuffering:
            break;
    }
}

- (void)mediaControlChannel:(id<KPGCMediaControlChannel>)mediaControlChannel
didCompleteLoadWithSessionID:(NSInteger)sessionID {
    _wasReadyToplay = YES;
    [self setDelegate:readyToPlay withValue:@(mediaControlChannel.mediaStatus.mediaInformation.streamDuration)];
}

- (void)setDelegate:(PlayerDelegateMethod)dMethod withValue:(id)value {
    if (_observers) {
        for (id<KCastMediaRemoteControlDelegate>observer in _observers.allObjects) {
            switch (dMethod) {
                case updateProgress:{
                    if ([observer respondsToSelector:@selector(updateProgress:)]) {
                        [observer updateProgress:[(NSNumber *)value doubleValue]];
                    }
                    break;
                }
                case castPlayerState:{
                    if ([observer respondsToSelector:@selector(castPlayerState:)]) {
                        [observer castPlayerState:value];
                    }
                    break;
                }
                case readyToPlay:{
                    if ([observer respondsToSelector:@selector(readyToPlay:)]) {
                        [observer readyToPlay:[(NSNumber *)value doubleValue]];
                    }
                    break;
                }
                default:
                    break;
            }
        }
    }
}

- (NSMutableSet *)observers {
    if (!_observers) {
        _observers = [NSMutableSet new];
    }
    
    return _observers;
}

- (void)addObserver:(id<KCastMediaRemoteControlDelegate>)observer {
    [self.observers addObject:observer];
}
- (void)removeObserver:(id<KCastMediaRemoteControlDelegate>)observer {
   [self.observers removeObject:observer];
}

- (id)mediaStatus {
    return _mediaChannel.mediaStatus;
}

@end
