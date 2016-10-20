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

#if GOOGLE_CAST_ENABLED

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
@property (nonatomic, copy) NSString *customLogo;
@property (nonatomic) PlayerState playerState;
@property (nonatomic, strong) NSMutableSet *observers;
@property (nonatomic) BOOL isChangeMedia;
@property (nonatomic) BOOL isEnded;
@property (nonatomic) BOOL wasReadyToplay;

@end

@implementation GoogleCastProvider

@synthesize currentTime = _currentTime;
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
    KPLogTrace(@"didStartCastSession Enter");
    [self castChannelModerator];
}

- (BOOL)isConnected {
    return _castChannel.isConnected;
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
     didEndCastSession:(GCKCastSession *)session
             withError:(NSError * GCK_NULLABLE_TYPE)error {
    KPLogTrace(@"didEndCastSession Enter");
    if (error) {
        KPLogError(@"JS Error %@", error.description);
    }
    
    [self sendTextMessage:@"{\"type\":\"hide\",\"target\":\"logo\"}"];
    [session removeChannel:_castChannel];
    _castChannel = nil;
    
    if ([self.delegate respondsToSelector:@selector(stopCasting)]) {
        [self.delegate stopCasting];
    }
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
       didStartSession:(GCKSession *)session {
    KPLogTrace(@"MediaViewController: sessionManager didStartSession %@", session);
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
 didFailToStartSession:(GCKSession *)session withError:(NSError *)error {
    if (error) {
        KPLogError(@"JS Error %@", error.description);
    }
    
    [self sendTextMessage:@"{\"type\":\"hide\",\"target\":\"logo\"}"];
    _castChannel = nil;
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
        // TODO:: attach captions implimantation
        // Converting NSString to NSDictionary
        //        NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
        //        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        //        if ([_delegate respondsToSelector:@selector(castProvider:availableTextTracks:)]) {
        //            [_delegate castProvider:self availableTextTracks:(NSDictionary *)json];
        //        }
    }
    
    
}

#pragma mark -

/**
 * Called when a session is about to be resumed.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(GCKSessionManager *)sessionManager willResumeSession:(GCKSession *)session {
    KPLogTrace(@"willResumeSession");
}

/**
 * Called when a session has been successfully resumed.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(GCKSessionManager *)sessionManager didResumeSession:(GCKSession *)session {
    KPLogTrace(@"didResumeSession");
}

/**
 * Called when a Cast session is about to be resumed.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(GCKSessionManager *)sessionManager
 willResumeCastSession:(GCKCastSession *)session {
    KPLogTrace(@"willResumeCastSession");
}

/**
 * Called when a Cast session has been successfully resumed.
 *
 * @param sessionManager The session manager.
 * @param session The Cast session.
 */
- (void)sessionManager:(GCKSessionManager *)sessionManager
  didResumeCastSession:(GCKCastSession *)session {
    KPLogTrace(@"didResumeCastSession");
    
    [self castChannelModerator];
}

#pragma mark -

- (void)castChannelModerator {
    if (!_castChannel) {
        _castChannel = [[GCKGenericChannel alloc] initWithNamespace:@"urn:x-cast:com.kaltura.cast.player"];
        _castChannel.delegate = self;
        _session = [GCKCastContext sharedInstance].sessionManager.currentSession;
        [_session.remoteMediaClient addListener:self];
        [_session addChannel:_castChannel];
        
        if (_customLogo) {
            [self sendTextMessage:[NSString stringWithFormat:@"{\"type\":\"setLogo\",\"logo\":\"%@\"",_customLogo]];
        }
        
        [self sendTextMessage:@"{\"type\":\"show\",\"target\":\"logo\"}"];
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
    
    if (_playerState != PlayerStatePlaying) {
        
        if (_isEnded || _isChangeMedia) {
            
            NSString *metaData = [[NSUserDefaults standardUserDefaults] objectForKey: @"MetaDataCC"];
            [self setVideoUrl:_mediaSrc startPosition:0 autoPlay:YES metaData: metaData];
            _isEnded = NO;
            _isChangeMedia = NO;
        } else {
            
            [self setVideoUrl:_mediaSrc startPosition:0 autoPlay:YES metaData: nil];
        }
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
    return _currentTime;
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

- (void)setVideoUrl:(NSString *)videoUrl startPosition:(NSTimeInterval)startPosition autoPlay:(BOOL)isAutoPlay metaData:(NSString *)info {
    KPLogTrace(@"setVideoUrl::: Position:%@, AutoPlay:%@", startPosition, isAutoPlay);
    
    if (!videoUrl && _mediaSrc) {
        videoUrl = _mediaSrc;
    }
    
    KPLogTrace(@"Video Url: ", videoUrl);
    
    GCKMediaInformation *mediaInfo = [[GCKMediaInformation alloc]
                                      initWithContentID:videoUrl
                                      streamType:GCKMediaStreamTypeBuffered
                                      contentType:@"video/mp4"
                                      metadata:[self p_metadataWithString: info]
                                      streamDuration:0
                                      mediaTracks:nil
                                      textTrackStyle:nil
                                      customData:nil];
    
    // Cast video
    if (self.currentSession.remoteMediaClient.mediaStatus.mediaInformation.contentID != mediaInfo.contentID || _isEnded) {
        [self stop];
        [self.currentSession.remoteMediaClient
         loadMedia:mediaInfo autoplay:isAutoPlay playPosition:startPosition];
    }
}

- (GCKMediaMetadata *) p_metadataWithString:(NSString *)value {
    
    GCKMediaMetadata *metadata = nil;
    if (value) {
        
        [[NSUserDefaults standardUserDefaults] setObject: value forKey: @"MetaDataCC"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if (dictionary != nil) {
            
            NSString *mediaId = @"";
            NSString *title = @"";
            NSString *thumbnailUrl = @"";
            NSString *description = @"";
            
            id media_id = [[[dictionary objectForKey:@"partnerData"] objectForKey:@"requestData"] objectForKey:@"MediaID"];
            if ([media_id isKindOfClass: [NSString class]]) {
                mediaId = (NSString *)media_id;
            }
            
            id title_ = [dictionary objectForKey:@"name"];
            if ([title_ isKindOfClass: [NSString class]]) {
                title = (NSString *)title_;
            }
            
            id thumbnailUrl_ = [dictionary objectForKey:@"thumbnailUrl"];
            if ([thumbnailUrl_ isKindOfClass: [NSString class]]) {
                thumbnailUrl = (NSString *)thumbnailUrl_;
            }
            
            id description_ = [dictionary objectForKey:@"description"];
            if ([description_ isKindOfClass: [NSString class]]) {
                description = (NSString *)description_;
            }
            
            metadata = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMovie];
            [metadata setString: title forKey:kGCKMetadataKeyTitle];
            [metadata setString: description forKey:kGCKMetadataKeySubtitle];
            [metadata setString: mediaId forKey: @"KEY_ENTRY_ID"];
            
            [metadata addImage:[[GCKImage alloc] initWithURL:[NSURL URLWithString:thumbnailUrl]
                                                       width:480
                                                      height:720]];
        }
    }
    
    return metadata;
}

- (void)startUpdateTime {
    if (self.currentSession.remoteMediaClient.mediaStatus.playerState
        == GCKMediaPlayerStatePlaying) {
        _currentTime = self.currentSession.remoteMediaClient.approximateStreamPosition;
        [self setDelegate:updateProgress
                withValue:[NSNumber numberWithDouble:self.currentSession.remoteMediaClient.approximateStreamPosition]];
        [self performSelector:@selector(startUpdateTime) withObject:nil afterDelay:0.2];
    }
}

- (void)stopUpdateTime {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(startUpdateTime) object:nil];
}

- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
     didUpdateMediaStatus:(GCKMediaStatus *)mediaStatus {
    switch (mediaStatus.playerState) {
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
    _wasReadyToplay = YES;
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

- (void)setLogo:(NSURL *)logoUrl {
    _customLogo = [logoUrl absoluteString];
}

@end
#endif
