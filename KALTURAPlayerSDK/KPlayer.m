//
//  KPlayer.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/12/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPlayer.h"
#import "KPLog.h"
#import <MediaPlayer/MediaPlayer.h>
#import "NSMutableDictionary+AdSupport.h"
#import "NSBundle+Kaltura.h"

/* Asset keys */
NSString * const TracksKey = @"tracks";
NSString * const PlayableKey = @"playable";
/* Player keys */
NSString * const RateKeyPath = @"rate";
/* PlayerItem keys */
NSString * const StatusKeyPath = @"status";
/* Player Max Try Count */
#define PLAYER_TRY_COUNT 20

@interface KPlayer() {
    MPVolumeView *volumeView;
    NSArray *prevAirPlayBtnPositionArr;
    id observer;
    AVPictureInPictureController *pip;
    NSString * playbackBufferEmptyKeyPath;
    NSString * playbackLikelyToKeepUpKeyPath;
    NSString * playbackBufferFullKeyPath;
    BOOL buffering;
    int _playerTryCounter;
}
@property (nonatomic, strong) AVPlayerLayer *layer;
@property (nonatomic, weak) UIView *parentView;
@property (nonatomic, strong) AVMediaSelectionGroup *audioSelectionGroup;
@end

@implementation KPlayer
@synthesize delegate = _delegate;
@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize duration = _duration;
@synthesize volume = _volume;
@synthesize mute = _mute;
@synthesize preferSubtitles = _preferSubtitles;
@synthesize isPlaying = _isPlaying;
@synthesize isIdle = _isIdle;

- (instancetype)initWithParentView:(UIView *)parentView {
    self = [super init];
    [self createAudioSession];
    _playerTryCounter = -1;
    
    if (self) {
        _layer = [AVPlayerLayer playerLayerWithPlayer:self];
        _layer.frame = (CGRect){CGPointZero, parentView.frame.size};
        _layer.backgroundColor = [UIColor blackColor].CGColor;
        _parentView = parentView;
        
        [self addPlayerToView];
        
        [self addObserver:self
               forKeyPath:RateKeyPath
                  options:0
                  context:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(videoEnded:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        __weak KPlayer *weakSelf = self;
        observer = [self addPeriodicTimeObserverForInterval:CMTimeMake(20, 100)
                                                      queue:dispatch_get_main_queue()
                    
                                                 usingBlock:^(CMTime time) {
                                                     [weakSelf updateCurrentTime:CMTimeGetSeconds(time)];
                                                     [weakSelf.delegate player:weakSelf eventName:TimeUpdateKey
                                                                         value:@(CMTimeGetSeconds(time)).stringValue];
                                                     //                                          [weakSelf.delegate eventName:ProgressKey
                                                     //                                                                 value:@(CMTimeGetSeconds(time) / weakSelf.duration).stringValue];
                                                 }];
        self.allowsExternalPlayback = YES;
        self.usesExternalPlaybackWhileExternalScreenIsActive = YES;
        [self setupPIPSuport];
        
        return self;
    }
    return nil;
}

- (void)addPlayerToView {
    if (_parentView.subviews.count) {
        UIWebView *wv = _parentView.subviews.lastObject;
        [_parentView.subviews.lastObject removeFromSuperview];
        [_parentView.layer.sublayers.firstObject removeFromSuperlayer];
        [_parentView.layer addSublayer:_layer];
        [_parentView addSubview:wv];
    } else {
        [_parentView.layer addSublayer:_layer];
    }
}

- (void)createAudioSession {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    
    if (!success) {
        /* handle the error condition */
        KPLogError(@"Audio Session error %@, %@", setCategoryError, [setCategoryError userInfo]);
        [self.delegate player:self
                    eventName:ErrorKey
                        value:[setCategoryError localizedDescription]];
    }
    
    NSError *activationError = nil;
    success = [audioSession setActive:YES error:&activationError];
    
    if (!success) {
        /* handle the error condition */
        KPLogError(@"Audio Session Activation error %@, %@", activationError, [activationError userInfo]);
        [self.delegate player:self
                    eventName:ErrorKey
                        value:[activationError localizedDescription]];
    }
}

- (BOOL)isKPlayer {
    return [self isMemberOfClass:[KPlayer class]];
}

- (AVMediaSelectionGroup *)audioSelectionGroup {
    if (!_audioSelectionGroup) {
        _audioSelectionGroup = [self.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    }
    return _audioSelectionGroup;
}

/*!
 * @function playerContinue:
 *
 * @abstract
 * Does the actual waiting and restarting
 */
- (void)playerContinue {
    KPLogTrace(@"Enter");
    
    if (CMTIME_COMPARE_INLINE(self.currentTime, ==, self.currentItem.duration)) { // we've reached the end
        [self reset];
    } else if (_playerTryCounter  > PLAYER_TRY_COUNT) { // stop trying
        [self reset];
        [self networkErrorNotifier];
    } else if (_playerTryCounter == 0) {
        return; // protects against a race condition
        
    } else if (self.currentItem.isPlaybackLikelyToKeepUp) {
        [self stopBuffering];
        _playerTryCounter = 0;
        [self play]; // continue from where we left off
    } else { // still hanging, not at end
        [self startBuffering];
        _playerTryCounter += 1;
        KPLogTrace(@"playerTryCounter::%d", _playerTryCounter);
        double delayInSeconds = 0.5;
        [self performSelector:@selector(tryToPlay) withObject:nil afterDelay:delayInSeconds];
    }
    
    KPLogTrace(@"Exit");
}

- (void)tryToPlay {
    KPLogTrace(@"Enter");
    
    if (_playerTryCounter > 0) {
        if (_playerTryCounter <= PLAYER_TRY_COUNT) {
            [self playerContinue];
        } else {
            [self reset];
            [self networkErrorNotifier];
        }
    }
    
    KPLogTrace(@"Exit");
}

/*!
 * @function playerHanging:
 *
 * @abstract
 * Simply decides whether to wait 0.5 seconds or not
 * if so, it pauses the player and sends a playerContinue notification
 * if not, send error message
 */
- (void)playerHanging {
    KPLogTrace(@"Enter");
    
    if (_playerTryCounter <= PLAYER_TRY_COUNT) {
        _playerTryCounter += 1;
        KPLogTrace(@"playerTryCounter::%d", _playerTryCounter);
        [self pause];
        [self startBuffering];
        [self playerContinue];
    } else {
        [self reset];
        [self networkErrorNotifier];
    }
    
    KPLogTrace(@"Exit");
}

/*!
 * @function networkErrorNotifier:
 *
 * @abstract
 * Creates error message and sends it to delegate method
 */
- (void)networkErrorNotifier {
    KPLogTrace(@"Enter");
    
    NSString * errorMsg = [NSString stringWithFormat:@"Player can't continue playing since there is network issue"];
    KPLogError(errorMsg);
    [self.delegate player:self
                eventName:ErrorKey
                    value:errorMsg];
    
    KPLogTrace(@"Exit");
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    NSNumber *oldValue = [change valueForKey:NSKeyValueChangeOldKey];
    NSNumber *newValue = [change valueForKey:NSKeyValueChangeNewKey];
    
    if (object == self.currentItem &&
        ([keyPath isEqualToString:playbackBufferEmptyKeyPath] ||
         [keyPath isEqualToString:playbackLikelyToKeepUpKeyPath] ||
         [keyPath isEqualToString:playbackBufferFullKeyPath])) {
            
            if (self.currentItem.isPlaybackBufferEmpty) {
                if (self.rate > 0) {
                    [self startBuffering];
                }
            } else if (self.currentItem.isPlaybackLikelyToKeepUp) {
                KPLogTrace(@"PlaybackLikelyToKeepUp");
                [self playerHanging];
            } else if (self.currentItem.isPlaybackBufferFull) {
                [self stopBuffering];
            }
        } else if ([keyPath isEqual:RateKeyPath]) {
            if (self.rate) {
                [self.delegate player:self
                            eventName:PlayKey
                                value:nil];
                _isPlaying = YES;
            } else {
                [self.delegate player:self
                            eventName:PauseKey
                                value:nil];
                _isPlaying = NO;
            }
        } else if ([keyPath isEqualToString:StatusKeyPath]) {
            switch (self.currentItem.status) {
                case AVPlayerItemStatusFailed:
                    KPLogError(@"AVPlayerItemStatusFailed");
                    [self.delegate player:self
                                eventName:ErrorKey
                                    value:[self.error localizedDescription]];
                    break;
                case AVPlayerItemStatusReadyToPlay: {
                    if (oldValue.intValue != newValue.intValue) {
                        [self registerForPlaybackNotification];
                        buffering = NO;
                        [self.delegate player:self
                                    eventName:DurationChangedKey
                                        value:@(self.duration).stringValue];
                        [self.delegate player:self
                                    eventName:LoadedMetaDataKey
                                        value:@""];
                        [self.delegate player:self
                                    eventName:CanPlayKey
                                        value:nil];
                        
                        if (self.currentItem.currentTime.value < _currentPlaybackTime) {
                            [self setCurrentPlaybackTime:_currentPlaybackTime];
                        }
                        
                        [self handleAudioTracks];
                        [self handleTextTracks];
                    }
                    break;
                case AVPlayerItemStatusUnknown:
                    KPLogError(@"AVPlayerStatusUnknown");
                    [self.delegate player:self
                                eventName:ErrorKey
                                    value:@"AVPlayerStatusUnknown"];
                    break;
                }
            }
        }
}
-(void)handleTextTracks{
    NSString* mc = AVMediaCharacteristicLegible;
    AVMediaSelectionGroup *group  = [self.currentItem.asset mediaSelectionGroupForMediaCharacteristic:mc];
    if (group){
        NSMutableArray *captions = [NSMutableArray array];
        NSMutableArray *subtitles = [NSMutableArray array];

        for (AVMediaSelectionOption *option in group.options){
            NSString *langCode = [option.locale objectForKey:NSLocaleLanguageCode];
            if (langCode == nil){
                langCode = @"en";
            }
            if ([option hasMediaCharacteristic:AVMediaCharacteristicContainsOnlyForcedSubtitles]){
                 [subtitles addObject:@{@"kind": @"subtitle",
                                 @"language": langCode,
                                 @"scrlang": langCode,
                                 @"label": langCode,
                                 @"index": @(subtitles.count),
                                 @"title": option.displayName}];
            }else{
                [captions addObject:@{@"kind": @"subtitle",
                                      @"language": langCode,
                                      @"scrlang": langCode,
                                      @"label": langCode,
                                      @"index": @(captions.count),
                                      @"title": option.displayName}];
            }
        }
        if ([subtitles count] > 0){
            NSMutableDictionary *languages = @{@"languages": subtitles}.mutableCopy;
            [self.delegate player:self eventName:@"textTracksReceived" JSON:languages.toJSON];


        }
        if ([captions count] > 0){
           NSMutableDictionary *closedCaptionLanguages = @{@"languages": captions}.mutableCopy;
           [self.delegate player:self eventName:@"closedCaptionsRecived" JSON:closedCaptionLanguages.toJSON];
        }
       

    }
}

-(void) selectTextTrack:(NSString *)locale {
    NSString* mc = AVMediaCharacteristicLegible;
    int index = 0;
    AVMediaSelectionGroup *group  = [self.currentItem.asset mediaSelectionGroupForMediaCharacteristic:mc];
    if (group) {
        BOOL selected = NO;
        for (AVMediaSelectionOption *option in group.options){
            if ([[option.locale objectForKey:NSLocaleLanguageCode] isEqual:locale]){
                if (_preferSubtitles){
                    if ([option hasMediaCharacteristic:AVMediaCharacteristicContainsOnlyForcedSubtitles]){
                      [[self currentItem] selectMediaOption:option inMediaSelectionGroup:group ];
                       selected = YES;
                    }
                } else {
                    if (![option hasMediaCharacteristic:AVMediaCharacteristicContainsOnlyForcedSubtitles]){
                        [[self currentItem] selectMediaOption:option inMediaSelectionGroup:group ];
                        selected = YES;
                    }
                }
            }
            index++;
        }

        if (!selected){
            [self.currentItem selectMediaOption:nil inMediaSelectionGroup:group];

        }
    }
}


-(void)handleAudioTracks{
    NSMutableArray* audioTracks;
    //check for multi audio
    AVMediaSelectionGroup *audioSelectionGroup = [[[self currentItem] asset] mediaSelectionGroupForMediaCharacteristic: AVMediaCharacteristicAudible];
    
    if (audioSelectionGroup.options.count > 1){
        audioTracks = [NSMutableArray new];
        //we have more than one audio assest - lets send events and be ready for a switch
        for (AVMediaSelectionOption *option in audioSelectionGroup.options){
            NSString* language = [option.locale objectForKey:NSLocaleLanguageCode];
            [audioTracks addObject:@{@"language":language,
                                     @"label":language,
                                     @"title":option.displayName,
                                     @"index": @(audioTracks.count)
                                     }];
        }
        if ([audioTracks count] > 0){
          NSMutableDictionary *audioLanguages = @{@"languages": audioTracks}.mutableCopy;
          [self.delegate player:self
                    eventName:@"audioTracksReceived"
                         JSON:audioLanguages.toJSON];
        }
    }
  
}

- (void)videoEnded:(NSNotification *)notification {
    // Make sure we don't call contentCompleted as a result of an ad completing.
    if (notification.object == self.currentItem) {
        [_delegate contentCompleted:self];
    }
}

- (void)removeStatusObserver {
    @try {
        if (self.currentItem != nil) {
            [self.currentItem removeObserver:self forKeyPath:StatusKeyPath context:nil];
            KPLogDebug(@"remove");
        }
    }
    @catch (NSException *exception) {
        KPLogError(@"%@", exception);
    }
}

- (void)setPlayerSource:(NSURL *)playerSource {
    [self setSourceWithAsset:[AVURLAsset assetWithURL:playerSource]];
}

-(void)setSourceWithAsset:(AVURLAsset*)asset {
    KPLogInfo(@"asset=%@", asset);
    
    NSArray *requestedKeys = @[TracksKey, PlayableKey];
    
    __weak KPlayer *weakSelf = self;
    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^() {
        dispatch_async( dispatch_get_main_queue(),
                       ^{
                           [weakSelf prepareToPlayAsset:asset withKeys:requestedKeys];
                       });
    }];
}

- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys {
    for (NSString *thisKey in requestedKeys) {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        
        if (keyStatus == AVKeyValueStatusFailed) {
            if (error != nil) {
                KPLogError(error.localizedDescription);
                [self.delegate player:self
                            eventName:ErrorKey
                                value:error.localizedDescription];
            }
            
            return;
        }
    }
    
    if (!asset.playable) {
        NSString * errorMsg = [NSString stringWithFormat:@"The follwoing source: %@ is not playable", asset.URL.absoluteString];
        KPLogError(errorMsg);
        [self.delegate player:self
                    eventName:ErrorKey
                        value:errorMsg];
        return;
    }
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    
    [self removeStatusObserver];
    [self unregisterForPlaybackNotification];
    
    
    [item addObserver:self
           forKeyPath:StatusKeyPath
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
              context:nil];
    
    if (self.currentItem != item) {
        [self replaceCurrentItemWithPlayerItem:item];
        if (!self.layer.superlayer) {
            [self addPlayerToView];
        }
    }
}

- (NSURL *)playerSource {
    // get current asset
    AVAsset *currentPlayerAsset = self.currentItem.asset;
    // make sure the current asset is an AVURLAsset
    if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) {
        return nil;
    }
    
    // return the NSURL
    return [(AVURLAsset *)currentPlayerAsset URL];
}

+ (BOOL)isPlayableMIMEType:(NSString *)mimeType {
    return @([AVURLAsset isPlayableExtendedMIMEType:mimeType]);
}


- (NSTimeInterval)duration {
    AVPlayerItem *item = self.currentItem;
    return CMTimeGetSeconds(item.asset.duration);
}

- (float)volume {
    return [super volume];
}

- (void)setVolume:(float)value {
    [super setVolume:value];
}

- (BOOL)isMuted {
    return super.isMuted;
}

- (void)setMute:(BOOL)isMute {
    self.muted = isMute;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
    if (self.currentItem.status != AVPlayerItemStatusReadyToPlay) {
        _currentPlaybackTime = currentPlaybackTime;
    } else if (currentPlaybackTime < self.duration) {
        _currentPlaybackTime = currentPlaybackTime;
        __weak KPlayer *weakSelf = self;
        [self.currentItem seekToTime:CMTimeMake(currentPlaybackTime, 1)
                   completionHandler:^(BOOL finished) {
                       [weakSelf.delegate player:self eventName:SeekedKey value:nil];
                   }];
    }
}

- (NSTimeInterval)currentPlaybackTime {
    return _currentPlaybackTime;
}

- (void)play {
    if (_isIdle) {
        return;
    }
    
    if (!self.rate) {
        [super play];
    }
}

- (void)pause {
    if (_isIdle) {
        return;
    }
    
    if (self.rate) {
        [super pause];
    }
}

- (void)removePlayer {
    [self pause];
    [self removeTimeObserver:observer];
    observer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    @try {
        [self removeObserver:self forKeyPath:RateKeyPath context:nil];
    }
    @catch (NSException *exception) {
        KPLogError(@"%@", exception);
    }
    
    [_layer removeFromSuperlayer];
    _layer = nil;
}

- (void)changeSubtitleLanguage:(NSString *)languageCode {
    //    self.currentItem selectMediaOption:<#(AVMediaSelectionOption *)#> inMediaSelectionGroup:<#(AVMediaSelectionGroup *)#>
}

-(void) selectAudioTrack:(int)trackId{
    AVMediaSelectionGroup *audioSelectionGroup = [[[self currentItem] asset] mediaSelectionGroupForMediaCharacteristic: AVMediaCharacteristicAudible];
    int index = 0;
    if (audioSelectionGroup.options.count > 1){
        //we have more than one audio assest - lets send events and be ready for a switch
        for (AVMediaSelectionOption *option in audioSelectionGroup.options){
            if (index == trackId){
                [[self currentItem] selectMediaOption:option inMediaSelectionGroup:audioSelectionGroup ];
                break;
            }
            index++;
        }
    }
    
}

- (void)removeAirPlayIcon {
    KPLogTrace(@"Enter");
    if ( volumeView ) {
        [volumeView removeFromSuperview];
        volumeView = nil;
    }
    KPLogTrace(@"Exit");
}
- (void)addNativeAirPlayButton {
    KPLogTrace(@"Enter");
    // Add airplay
    _parentView.backgroundColor = [UIColor clearColor];
    if ( !volumeView ) {
        volumeView = [ [MPVolumeView alloc] init ];
        [volumeView setShowsVolumeSlider: NO];
    }
    KPLogTrace(@"Exit");
}

-(void)showNativeAirPlayButton: (NSArray*)airPlayBtnPositionArr {
    KPLogTrace(@"Enter");
    if ( volumeView.hidden ) {
        volumeView.hidden = NO;
        
        if ( prevAirPlayBtnPositionArr == nil || ![prevAirPlayBtnPositionArr isEqualToArray: airPlayBtnPositionArr] ) {
            prevAirPlayBtnPositionArr = airPlayBtnPositionArr;
        }else {
            return;
        }
    }
    
    CGFloat x = [airPlayBtnPositionArr[0] floatValue];
    CGFloat y = [airPlayBtnPositionArr[1] floatValue];
    CGFloat w = [airPlayBtnPositionArr[2] floatValue];
    CGFloat h = [airPlayBtnPositionArr[3] floatValue];
    
    volumeView.frame = CGRectMake( x, y, w, h );
    
    [_parentView addSubview:volumeView];
    [_parentView bringSubviewToFront:volumeView];
    KPLogTrace(@"Exit");
}

- (void)togglePictureInPicture {
    if (pip.pictureInPictureActive) {
        [pip stopPictureInPicture];
    } else {
        [pip startPictureInPicture];
    }
}

-(void)hideNativeAirPlayButton {
    KPLogTrace(@"Enter");
    if ( !volumeView.hidden ) {
        volumeView.hidden = YES;
    }
    KPLogTrace(@"Exit");
}

- (void)updateCurrentTime:(NSTimeInterval)currentTime {
    _currentPlaybackTime = currentTime;
}

- (void)enableTracks:(BOOL)isEnablingTracks {
    KPLogTrace(@"Enter");
    
    AVPlayerItem *playerItem = self.currentItem;
    
    NSArray *tracks = [playerItem tracks];
    
    for (AVPlayerItemTrack *playerItemTrack in tracks) {
        // find video tracks
        if ([playerItemTrack.assetTrack hasMediaCharacteristic:AVMediaCharacteristicVisual]) {
            playerItemTrack.enabled = isEnablingTracks; // enable or disable the track
        }
    }
    
    // Setting remote command center if tracks are not enabled
    if(!isEnablingTracks) {
        [MPRemoteCommandCenter sharedCommandCenter].playCommand.enabled = YES;
        [[MPRemoteCommandCenter sharedCommandCenter].playCommand removeTarget:self];
        [[MPRemoteCommandCenter sharedCommandCenter].playCommand addTarget:self action:@selector(play)];
        
        [MPRemoteCommandCenter sharedCommandCenter].pauseCommand.enabled = YES;
        [[MPRemoteCommandCenter sharedCommandCenter].pauseCommand removeTarget:self];
        [[MPRemoteCommandCenter sharedCommandCenter].pauseCommand addTarget:self action:@selector(pause)];
    }
    
    KPLogTrace(@"Exit");
}

- (void)registerForPlaybackNotification {
    if (self.currentItem == nil) {
        return;
    }
    
    __weak KPlayer *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemPlaybackStalledNotification
                                                      object:self.currentItem
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      KPLogTrace(@"%@", @"AVPlayerItemPlaybackStalledNotification");
                                                      [weakSelf playerHanging];
                                                  }];
    
    playbackBufferEmptyKeyPath = NSStringFromSelector(@selector(playbackBufferEmpty));
    playbackLikelyToKeepUpKeyPath = NSStringFromSelector(@selector(playbackLikelyToKeepUp));
    playbackBufferFullKeyPath = NSStringFromSelector(@selector(playbackBufferFull));
    
    [self.currentItem addObserver:self forKeyPath:playbackBufferEmptyKeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.currentItem addObserver:self forKeyPath:playbackLikelyToKeepUpKeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [self.currentItem addObserver:self forKeyPath:playbackBufferFullKeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (void)unregisterForPlaybackNotification {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemPlaybackStalledNotification
                                                      object:nil];
        [self.currentItem removeObserver:self forKeyPath:playbackBufferEmptyKeyPath];
        [self.currentItem removeObserver:self forKeyPath:playbackLikelyToKeepUpKeyPath];
        [self.currentItem removeObserver:self forKeyPath:playbackBufferFullKeyPath];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tryToPlay) object:nil];
    }
    @catch (NSException *exception) {
        KPLogError(@"%@", exception);
    }
}

- (void)startBuffering {
    KPLogTrace(@"startBuffering");
    if (self.delegate != nil && !buffering) {
        [self.delegate player:self
                    eventName:BufferingChangeKey
                        value:@"true"];
        buffering = YES;
    }
}

- (void)stopBuffering {
    KPLogTrace(@"stopBuffering");
    if (self.delegate != nil && buffering) {
        [self.delegate player:self
                    eventName:BufferingChangeKey
                        value:@"false"];
        buffering = NO;
    }
}

- (void)setupPIPSuport {
    if([NSBundle mainBundle].isAudioBackgroundModesEnabled &&
       [AVPictureInPictureController isPictureInPictureSupported]) {
        pip = [[AVPictureInPictureController alloc] initWithPlayerLayer:_layer];
    }
}

- (void)reset {
    if (self.currentItem) {
        [self seekToTime:kCMTimeZero];
        [self removeStatusObserver];
        [self unregisterForPlaybackNotification];
        [self replaceCurrentItemWithPlayerItem:nil];
    }
}

- (void)hidePlayer {
    if (self) {
        [self reset];
        [self.layer removeFromSuperlayer];
    }
}

- (void)dealloc {
    KPLogInfo(@"Dealloc");
    [self unregisterForPlaybackNotification];
    [self removeStatusObserver];
    _delegate = nil;
    _parentView = nil;
    _audioSelectionGroup = nil;
    observer = nil;
    volumeView = nil;
    prevAirPlayBtnPositionArr = nil;
    pip = nil;
}

@end
