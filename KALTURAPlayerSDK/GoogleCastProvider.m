//
//  GoogleCastProvider.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 18/09/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "GoogleCastProvider.h"
#import "KPLog.h"
#import "NSString+Utilities.h"

typedef NS_ENUM(NSInteger, PlayerDelegateMethod) {
    updateProgress,
    castPlayerState,
    readyToPlay
};

typedef NS_ENUM(NSInteger, PlayerState) {
    PlayerStatePause,
    PlayerStatePlaying,
    PlayerStateSeeking
};

@interface GoogleCastProvider () <GCKSessionManagerListener, GCKGenericChannelDelegate, GCKRemoteMediaClientListener> {
}

@property (nonatomic, strong)  GCKGenericChannel *castChannel;
@property (nonatomic, strong)  GCKCastSession *session;
@property (nonatomic, strong, readonly)  GCKCastSession *currentSession;
@property (nonatomic, copy) NSString *mediaSrc;
@property (nonatomic) PlayerState playerState;
@property (nonatomic, strong) NSMutableSet *observers;
@property (nonatomic) BOOL isChangeMedia;
@property (nonatomic) BOOL isEnded;
@property (nonatomic) BOOL wasReadyToplay;

@end

@implementation GoogleCastProvider

@synthesize delegate = _delegate;
@synthesize wasReadyToplay = _wasReadyToplay;

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [[GCKCastContext sharedInstance].sessionManager addListener:self];
    }
    
    return self;
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
   didStartCastSession:(GCKCastSession *)session {
    if (!_castChannel) {
        _castChannel = [[GCKGenericChannel alloc] initWithNamespace:@"urn:x-cast:com.kaltura.cast.player"];
        _castChannel.delegate = self;
        _session = session;
        [_session.remoteMediaClient addListener:self];
        [_session addChannel:_castChannel];
        [self sendTextMessage:@"{\"type\":\"show\",\"target\":\"logo\"}"];
    }
}

- (BOOL)isConnected {
    return YES;
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
     didEndCastSession:(GCKCastSession *)session
             withError:(NSError * GCK_NULLABLE_TYPE)error {
    if (error) {
        KPLogError(@"JS Error %@", error.description);
    }
    
    [self sendTextMessage:@"{\"type\":\"hide\",\"target\":\"logo\"}"];
    [session removeChannel:_castChannel];
    _castChannel = nil;
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
       didStartSession:(GCKSession *)session {
    NSLog(@"MediaViewController: sessionManager didStartSession %@", session);

}

- (void)castChannelDidConnect:(GCKGenericChannel *)channel {
    NSLog(@"");
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
 didFailToStartSession:(GCKSession *)session withError:(NSError *)error {
    /// TODO:: error
    [self sendTextMessage:@"{\"type\":\"hide\",\"target\":\"logo\"}"];
    // remove _cast channel
    
}

- (void)castChannel:(GCKGenericChannel *)channel
didReceiveTextMessage:(NSString *)message
      withNamespace:(NSString *)protocolNamespace {
    NSLog(@"didReceiveTextMessage::%@", message);
    if ([message hasPrefix:@"readyForMedia"]) {
        KPLogTrace(@"message::%@", message);
        [_castChannel sendTextMessage:@"{\"type\":\"hide\",\"target\":\"logo\"}"];
        NSArray *castParams = message.castParams;
        
        if (castParams) {
            // set new media source - for change media
            [self setMediaSrc:[castParams firstObject]];
        }
        
        if ([self.delegate respondsToSelector:@selector(startCasting)]) {
            [self.delegate startCasting];
        }
    } else if ([message hasPrefix:@"changeMedia"]) {
        // pause cast player before changing media
        [self pause];
    } else if ([message containsString:@"captions"]) {
        KPLogTrace(@"message:: %@", message);
        // Converting NSString to NSDictionary
//        NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
//        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//        if ([_delegate respondsToSelector:@selector(castProvider:availableTextTracks:)]) {
//            [_delegate castProvider:self availableTextTracks:(NSDictionary *)json];
//        }
    }


}

- (GCKCastSession *)currentSession {
    return [GCKCastContext sharedInstance].sessionManager.currentCastSession;
}

- (void)setMediaSrc:(NSString *)mediaSrc {
    if (_mediaSrc != nil) {
        _isChangeMedia = YES;
        _mediaSrc = mediaSrc;
    } else {
        _mediaSrc = mediaSrc;
    }
}

- (void)play {
    
    if ((_isEnded || _isChangeMedia) && _playerState != PlayerStatePlaying) {
        [self setVideoUrl:_mediaSrc startPosition:0 autoPlay:YES];
        _isEnded = NO;
        _isChangeMedia = NO;
        return;
    }
    if (_playerState == PlayerStatePause) {
        [self.currentSession.remoteMediaClient play];
    }
}

- (void)pause {
    [self.currentSession.remoteMediaClient pause];
}

- (void)stop {
    [self.currentSession.remoteMediaClient stop];
}

- (NSInteger)seekToTimeInterval:(NSTimeInterval)position {
    _playerState = PlayerStateSeeking;
    return [self.currentSession.remoteMediaClient seekToTimeInterval:position];
}

- (NSInteger)setStreamVolume:(float)volume {
    return [self.currentSession.remoteMediaClient setStreamVolume:volume];
}

- (NSInteger)setStreamMuted:(BOOL)muted {
    return [self.currentSession.remoteMediaClient setStreamMuted:muted];
}

- (NSTimeInterval)currentTime {
    return self.currentSession.remoteMediaClient.approximateStreamPosition;
}

- (BOOL)wasReadyToplay {
    return _wasReadyToplay;
}

- (BOOL)sendTextMessage:(NSString *)message {
    NSLog(@"sendmessage::: %@", message);
    if (_castChannel) {
        return [_castChannel sendTextMessage:message];
    }
    
    return NO;
}

- (void)setVideoUrl:(NSString *)videoUrl startPosition:(NSTimeInterval)startPosition autoPlay:(BOOL)isAutoPlay {
    KPLogTrace(@"setVideoUrl::: Position:%@, AutoPlay:%@", startPosition, isAutoPlay);
    
    if (!videoUrl && _mediaSrc) {
        videoUrl = _mediaSrc;
    }

    KPLogTrace(@"Video Url: ", videoUrl);
    
    GCKMediaInformation *mediaInfo = [[GCKMediaInformation alloc]
                                      initWithContentID:videoUrl
                                      streamType:GCKMediaStreamTypeBuffered
                                      contentType:@"video/mp4"
                                      metadata:nil
                                      streamDuration:0
                                      mediaTracks:nil
                                      textTrackStyle:nil
                                      customData:nil];
    
//    if (self.session) {
//        [_session.remoteMediaClient addListener:self];
//        [self.currentSession.remoteMediaClient
//         loadMedia:mediaInfo autoplay:isAutoPlay playPosition:startPosition];
//    }
    
    // Cast the video.
    if (self.currentSession.remoteMediaClient.mediaStatus.mediaInformation.contentID != mediaInfo.contentID || _isEnded) {
        [self stop];
        [self.currentSession.remoteMediaClient
         loadMedia:mediaInfo autoplay:isAutoPlay playPosition:startPosition];
    }
}

- (void)startUpdateTime {
//    if (self.currentSession.remoteMediaClient.mediaStatus == GCKMediaPlayerStatePlaying) {
        [self setDelegate:updateProgress
                withValue:[NSNumber numberWithDouble:self.currentSession.remoteMediaClient.approximateStreamPosition]];
        [self performSelector:@selector(startUpdateTime) withObject:nil afterDelay:0.2];
//    }
}

- (void)stopUpdateTime {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startUpdateTime) object:nil];
}

- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
     didUpdateMediaStatus:(GCKMediaStatus *)mediaStatus {
    switch ([mediaStatus playerState]) {
            KPLogDebug(@"mediaControlChannelDidUpdateStatus");
        case GCKMediaPlayerStateUnknown:
            break;
        case GCKMediaPlayerStateIdle:
            if ([mediaStatus idleReason] == GCKMediaPlayerIdleReasonFinished) {
                _isEnded = YES;
                _playerState = PlayerStatePause;
                [self setDelegate:castPlayerState withValue:@"ended"];
            }
            break;
        case GCKMediaPlayerStatePlaying:
            if (_playerState == PlayerStateSeeking) {
                [self setDelegate:castPlayerState withValue:@"seeked"];
            } else {
                [self setDelegate:castPlayerState withValue:@"play"];
            }
            _playerState = PlayerStatePlaying;
            [self startUpdateTime];
            break;
        case GCKMediaPlayerStatePaused:
            if (_playerState == PlayerStateSeeking) {
                [self setDelegate:castPlayerState withValue:@"seeked"];
            } else {
                [self setDelegate:castPlayerState withValue:@"pause"];
            }
            _playerState = PlayerStatePause;
            [self stopUpdateTime];
            break;
        case GCKMediaPlayerStateBuffering:
            break;
    }

}

- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
didStartMediaSessionWithID:(NSInteger)sessionID {
    [self setDelegate:readyToPlay withValue:
     @(self.currentSession.remoteMediaClient.mediaStatus.mediaInformation.streamDuration)];
}

- (void)setDelegate:(PlayerDelegateMethod)dMethod withValue:(id)value {
    if (_observers) {
        for (id<KPCastProviderDelegate>observer in _observers.allObjects) {
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

- (void)addObserver:(id<KPCastProviderDelegate>)observer {
    [self.observers addObject:observer];
}
- (void)removeObserver:(id<KPCastProviderDelegate>)observer {
    [self.observers removeObject:observer];
}

@end
