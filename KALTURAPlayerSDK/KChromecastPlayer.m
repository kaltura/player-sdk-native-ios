//
//  KChromecastPlayer.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 02/06/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KChromecastPlayer.h"
#import "NSString+Utilities.h"

typedef NS_ENUM(NSInteger, PlayerState) {
    PlayerStatePause,
    PlayerStatePlaying,
    PlayerStateSeeking
};

@interface KChromecastPlayer()
@property (nonatomic, strong) id<KPGCMediaControlChannel> mediaChannel;
@property (nonatomic) PlayerState playerState;
@end


@implementation KChromecastPlayer

- (instancetype)initWithMediaChannel:(id<KPGCMediaControlChannel>)mediaChannel {
    self = [super init];
    if (self) {
        _mediaChannel = mediaChannel;
        _mediaChannel.delegate = self;
        return self;
    }
    return nil;
}

- (void)setVideoUrl:(NSString *)videoUrl
      startPosition:(NSTimeInterval)startPosition {
    id<KPGCMediaInformation> mediaInformation = [[NSClassFromString(@"GCKMediaInformation") alloc] initWithContentID:videoUrl
                                                                                                          streamType:0
                                                                                                         contentType:videoUrl.mimeType
                                                                                                            metadata:nil
                                                                                                      streamDuration:0
                                                                                                          customData:nil];
    
    // Cast the video.
    [_mediaChannel loadMedia:mediaInformation autoplay:NO playPosition:startPosition];
}

- (void)play {
    if (_playerState == PlayerStatePause) {
        [_mediaChannel play];
    }
}

- (void)pause {
    if (_playerState == PlayerStatePlaying) {
        [_mediaChannel pause];
    }
}

- (void)seek:(NSTimeInterval)time {
    _playerState = PlayerStateSeeking;
    [_mediaChannel seekToTimeInterval:time];
}

- (void)startUpdateTime {
    if (_mediaChannel.mediaStatus.playerState == KPGCMediaPlayerStatePlaying) {
        _currentTime = _mediaChannel.approximateStreamPosition;
        [_delegate updateProgress:_currentTime];
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
                [_delegate castPlayerState:@"ended"];
            }
            break;
        case KPGCMediaPlayerStatePlaying:
            if (_playerState == PlayerStateSeeking) {
                [_delegate castPlayerState:@"seeked"];
            } else {
                [_delegate castPlayerState:@"play"];
            }
            _playerState = PlayerStatePlaying;
            [self startUpdateTime];
            break;
        case KPGCMediaPlayerStatePaused:
            if (_playerState == PlayerStateSeeking) {
                [_delegate castPlayerState:@"seeked"];
            } else {
                [_delegate castPlayerState:@"pause"];
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
    [_delegate readyToPlay:mediaControlChannel];
}
@end
