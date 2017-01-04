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
@synthesize thumbnailUrl = _thumbnailUrl;

#pragma mark - Life cycle

+ (GoogleCastProvider *)sharedInstance {
    
    static GoogleCastProvider *sharedClass = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClass = [[self alloc] init];
    });
    
    return sharedClass;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [[GCKCastContext sharedInstance].sessionManager addListener:self];
    }
    
    return self;
}

- (void)castChannelModerator {
    if (!_castChannel) {
        _castChannel = [[GCKGenericChannel alloc] initWithNamespace:@"urn:x-cast:com.kaltura.cast.player"];
        _castChannel.delegate = self;
        
        self.session = [GCKCastContext sharedInstance].sessionManager.currentCastSession;
        [_session.remoteMediaClient addListener:self];
        [_session addChannel:_castChannel];
        
        if (_customLogo) {
            [self sendTextMessage:[NSString stringWithFormat:@"{\"type\":\"setLogo\",\"logo\":\"%@\"}",_customLogo]];
        }
        
        [self sendTextMessage:@"{\"type\":\"show\",\"target\":\"logo\"}"];
    }
}

#pragma mark -

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

#pragma mark - Private methods

- (NSString *)videoUrlModeratorWithString: (NSString *)url {
    
    NSString *videoUrl = url;
    
    NSString *videoUrlUD = [[NSUserDefaults standardUserDefaults] valueForKey: @"videoUrl"];
    
    if (_mediaSrc == nil) {
        self.mediaSrc = videoUrlUD;
    }
    
    if (!videoUrl && _mediaSrc) {
        videoUrl = _mediaSrc;
    }
    
    return videoUrl;
}

- (GCKMediaInformation *)p_buildMediaInformationWithVideoUrl:(NSString *)videoUrl info:(NSString *)value {
    KPLogTrace(@"Video Url: ", videoUrl);
    
//    NSInteger duration = [metaData objectForKey:@"duration"];
//    NSTimeInterval dur = duration;
    
    GCKMediaMetadata *metaData = [self p_metadataWithString: value];
    
    GCKMediaInformation *mediaInfo = [[GCKMediaInformation alloc]
                                          initWithContentID: videoUrl
                                          streamType: GCKMediaStreamTypeBuffered
                                          contentType: @"video/mp4"
                                          metadata: metaData
                                          streamDuration: 0
                                          mediaTracks:nil
                                          textTrackStyle:nil
                                          customData:nil];
    
    return mediaInfo;
}

- (GCKMediaMetadata *)p_metadataWithString:(NSString *)value {
    
    GCKMediaMetadata *metadata = nil;
    if (value) {
        
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:@"MetaDataCC"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if (dictionary != nil) {
            
            NSString *mediaId = @"";
            NSString *title = @"";
            NSString *thumbnailUrl = @"";
            NSString *description = @"";
            NSNumber *duration = @0;
            
            id media_id = nil;
            
            id partner_data = [dictionary objectForKey:@"partnerData"];
            if ([partner_data isKindOfClass: [NSDictionary class]]) {
                //OTT
                id requestData = [((NSDictionary *)partner_data) objectForKey: @"requestData"];
                if ([requestData isKindOfClass: [NSDictionary class]]) {
                    
                    media_id = [((NSDictionary *)requestData) objectForKey: @"MediaID"];
                }
            } else {
                //OVP
                mediaId =  [dictionary objectForKey:@"id"];
            }
            
            if ([media_id isKindOfClass: [NSString class]]) {
                mediaId = (NSString *)media_id;
            }
            
            id title_ = [dictionary objectForKey:@"name"];
            if ([title_ isKindOfClass: [NSString class]]) {
                title = (NSString *)title_;
            }
            
            if (_thumbnailUrl) {
                thumbnailUrl = _thumbnailUrl;
            } else {
                id thumbnailUrl_ = [dictionary objectForKey:@"thumbnailUrl"];
                
                if ([thumbnailUrl_ isKindOfClass: [NSString class]]) {
                    thumbnailUrl = (NSString *)thumbnailUrl_;
                    thumbnailUrl = [NSString stringWithFormat: @"%@/width/1200/hight/780", thumbnailUrl];
                }
                
                if(!thumbnailUrl_ || [(NSString *)thumbnailUrl_ isEqualToString:@""]) {
                    if (_thumbnailUrl) {
                        thumbnailUrl = _thumbnailUrl;
                    }
                }
            }
            
            id description_ = [dictionary objectForKey:@"description"];
            if ([description_ isKindOfClass: [NSString class]]) {
                description = (NSString *)description_;
            }
            
            id duration_ = [dictionary objectForKey: @"duration"];
            if ([duration_ isKindOfClass: [NSNumber class]]) {
                
                duration = (NSNumber *)duration_;
            }
            
            metadata = [[GCKMediaMetadata alloc] initWithMetadataType:GCKMediaMetadataTypeMovie];
            [metadata setString: title forKey:kGCKMetadataKeyTitle];
            [metadata setString: description forKey:kGCKMetadataKeySubtitle];
            [metadata setString: mediaId forKey: @"entryid"];
            [metadata setInteger:duration.integerValue forKey:@"duration"];
            
            [metadata addImage:[[GCKImage alloc] initWithURL:[NSURL URLWithString:thumbnailUrl]
                                                       width:480
                                                      height:720]];
        }
    }
    
    return metadata;
}

- (void)p_switchToRemotePlayback {
    
    if ([self.delegate respondsToSelector:@selector(startCasting)]) {
        [self.delegate startCasting];
    }
}

#pragma mark - KPCastProvider

- (void)setVideoUrl:(NSString *)videoUrl startPosition:(NSTimeInterval)startPosition autoPlay:(BOOL)isAutoPlay metaData:(NSString *)info {
    KPLogTrace(@"setVideoUrl::: Position:%@, AutoPlay:%@", startPosition, isAutoPlay);
    
    self.session = [GCKCastContext sharedInstance].sessionManager.currentCastSession;
    
    NSString *mediaUrl = [self videoUrlModeratorWithString: videoUrl];
    GCKMediaInformation *mediaInfo = [self p_buildMediaInformationWithVideoUrl: mediaUrl info: info];
    
    KPLogTrace(@"Video Url: ", mediaUrl);
    
    if (mediaUrl == nil) {
        
        [self p_switchToRemotePlayback];
    } else {
        
        // Cast video
        if (_session.remoteMediaClient.mediaStatus.mediaInformation.contentID != mediaInfo.contentID || _isEnded) {
            [self stop];
            
            if (_session) {
                [_session.remoteMediaClient loadMedia:mediaInfo
                                             autoplay:YES 
                                         playPosition:startPosition];
                
                return;
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

- (BOOL)isConnected {
    return _castChannel.isConnected;
}

- (void)updateAdTagUrl:(NSString *)newAdTagUrl {
    if (newAdTagUrl && self.currentSession.remoteMediaClient.mediaStatus != nil) {
        NSString *changeAdTagUrlMsg = [NSString stringWithFormat:@"{\"type\":\"setKDPAttribute\",\"plugin\":\"doubleClick\",\"property\":\"adTagUrl\",\"value\":\"%@\"}", newAdTagUrl];
        [self sendTextMessage:changeAdTagUrlMsg];
    }
}

- (void)setThumbnailUrl:(NSString *)thumbnailUrl {
    _thumbnailUrl = thumbnailUrl;
}

- (BOOL)wasReadyToplay {
    return _wasReadyToplay;
}

- (NSTimeInterval)currentTime {
    return _currentTime;
}

- (NSInteger)seekToTimeInterval:(NSTimeInterval)position {
    _playerState = PlayerStateSeeking;
    return [self.currentSession.remoteMediaClient seekToTimeInterval:position];
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

- (NSInteger)setStreamVolume:(float)volume {
    return [self.currentSession.remoteMediaClient setStreamVolume:volume];
}

- (NSInteger)setStreamMuted:(BOOL)muted {
    return [self.currentSession.remoteMediaClient setStreamMuted:muted];
}

- (BOOL)sendTextMessage:(NSString *)message {
    NSLog(@"sendmessage::: %@", message);
    if (_castChannel) {
        return [_castChannel sendTextMessage:message];
    }
    
    return NO;
}

#pragma mark - GCKRemoteMediaClientListener

- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
didStartMediaSessionWithID:(NSInteger)sessionID {
    _wasReadyToplay = YES;
    [self setDelegate:readyToPlay withValue:
     @(self.currentSession.remoteMediaClient.mediaStatus.mediaInformation.streamDuration)];
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

#pragma mark - GCKGenericChannelDelegate

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
            
            NSString *mediaUrl = [castParams firstObject];
            [self setMediaSrc:mediaUrl];
            [[NSUserDefaults standardUserDefaults] setObject:mediaUrl forKey:@"mediaUrl"];
            [[NSUserDefaults standardUserDefaults] synchronize];
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

#pragma mark - GCKSessionManagerListener

- (void)sessionManager:(GCKSessionManager *)sessionManager
   didStartCastSession:(GCKCastSession *)session {
    KPLogTrace(@"didStartCastSession Enter");
    [self castChannelModerator];
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
    
    [_session addChannel:_castChannel];
    [self p_switchToRemotePlayback];
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
         didEndSession:(GCKSession *)session
             withError:(NSError *)error {
    KPLogTrace(@"session ended with error: %@", error);
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
 didFailToStartSession:(GCKSession *)session withError:(NSError *)error {
    if (error) {
        KPLogError(@"JS Error %@", error.description);
    }
    
    [self sendTextMessage:@"{\"type\":\"hide\",\"target\":\"logo\"}"];
    _castChannel = nil;
}

@end
#endif
