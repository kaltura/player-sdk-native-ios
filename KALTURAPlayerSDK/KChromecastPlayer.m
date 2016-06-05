//
//  KChromecastPlayer.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 02/06/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KChromecastPlayer.h"

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

- (void)setVideoUrl:(NSString *)videoUrl {
    id<KPGCMediaInformation> mediaInformation = [[NSClassFromString(@"GCKMediaInformation") alloc] initWithContentID:@"https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                                                                                                          streamType:0
                                                                                                         contentType:@"video/mp4"
                                                                                                            metadata:nil
                                                                                                      streamDuration:0
                                                                                                          customData:nil];
    
    // Cast the video.
    [_mediaChannel loadMedia:mediaInformation autoplay:NO playPosition:0];
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
                [_delegate stateChanged:@"ended"];
            }
            break;
        case KPGCMediaPlayerStatePlaying:
            if (_playerState == PlayerStateSeeking) {
                [_delegate stateChanged:@"seeked"];
            } else {
                [_delegate stateChanged:@"play"];
            }
            _playerState = PlayerStatePlaying;
            [self startUpdateTime];
            break;
        case KPGCMediaPlayerStatePaused:
            if (_playerState == PlayerStateSeeking) {
                [_delegate stateChanged:@"seeked"];
            } else {
                [_delegate stateChanged:@"pause"];
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
