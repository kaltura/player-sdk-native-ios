//
//  KPlayerManager.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/16/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPlayerFactory.h"
#import "WidevineClassicCDM.h"
#import "KPLog.h"
#import "NSString+Utilities.h"
#import "KPAssetBuilder.h"
#import "CastProviderInternalDelegate.h"
#import "KChromeCastWrapper.h"
#import "KChromecastPlayer.h"

typedef NS_ENUM(NSInteger, CurrentPlyerType) {
    CurrentPlyerTypeDefault,
    CurrentPlyerTypeIMA,
    CurrentPlyerTypeCast
};

@interface KCastProvider ()
//@property (nonatomic, readonly) id<KCastChannel> castChannel;
@property (nonatomic, weak) id<CastProviderInternalDelegate> internalDelegate;
@end

@interface KPlayerFactory() <KPlayerDelegate, CastProviderInternalDelegate, KChromecastPlayerDelegate> {
    NSString *key;
    BOOL isSeeked;
    BOOL isReady;
    BOOL _backToForeground;
    NSTimeInterval _lastPosition;
    CurrentPlyerType currentPlayerType;
    BOOL isPlaying;
}

@property (nonatomic, strong) UIViewController *parentViewController;
@property (nonatomic) BOOL isContentEnded;
@property (nonatomic) BOOL isAllAdsCompleted;
@property (nonatomic, retain) KPAssetBuilder* assetBuilder;
@property (nonatomic, strong) KChromecastPlayer *castPlayer;
@end

@implementation KPlayerFactory
@synthesize currentPlayBackTime = _currentPlayBackTime;

- (void)backToForeground {
    KPLogTrace(@"Enter backToForeground");
    if ([_assetBuilder requiresBackToForegroundHandling]) {
        _lastPosition = [self.player currentPlaybackTime];
        _backToForeground = YES;
        [_assetBuilder backToForeground];
    }
    KPLogTrace(@"Exit backToForeground");
}

- (instancetype)initWithPlayerClassName:(NSString *)className {
    self = [super init];
    if (self) {
        self.playerClassName = className;
        return self;
    }
    return nil;
}


- (void)addPlayerToController:(UIViewController *)parentViewController {
    _parentViewController = parentViewController;
    if (!self.player) {
        KPLogError(@"%@", @"NO PLAYER CREATED");
    }
}

- (id<KPlayer>)player {
    if (!_player) {
        Class class = NSClassFromString(_playerClassName);
        _player = [(id<KPlayer>)[class alloc] initWithParentView:_parentViewController.view];
        _player.delegate = self;
    }
    return _player;
}

- (NSString *)getMimeType:(NSURL * )mediaUrl {
    __block NSString *mimeType = nil;
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:mediaUrl]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               mimeType = [response MIMEType];
                           }];
    return mimeType;
}

- (void)setSrc:(NSString *)src {
    isReady = NO;
    _src = src;
    
    id<KPlayer> player = _player;
    
    _assetBuilder = [[KPAssetBuilder alloc] initWithReadyCallback:^(AVURLAsset *avAsset) {
        [player setSourceWithAsset:avAsset];
    }];
    [_assetBuilder setContentUrl:src];
}

-(void)setLicenseUri:(NSString*)licenseUri {
    [_assetBuilder setLicenseUri:licenseUri];
}

- (void)setAssetParam:(NSString*)_key toValue:(id)value {
    [_assetBuilder setAssetParam:_key toValue:value];
}

- (NSTimeInterval)currentPlayBackTime {
    return _player.currentPlaybackTime;
}

- (void)setCurrentPlayBackTime:(NSTimeInterval)currentPlayBackTime {
    if (currentPlayerType == CurrentPlyerTypeCast) {
        [_castPlayer seek:currentPlayBackTime];
        return;
    }
    if (isReady) {
        _player.currentPlaybackTime = currentPlayBackTime;
    } else {
        _currentPlayBackTime = currentPlayBackTime;
    }
}

- (void)setAdTagURL:(NSString *)adTagURL {
    if (!_adController) {
        _adController = [KPIMAPlayerViewController new];

        if (!_adController) {
        
            return;
        }
        
        _adController.delegate = self;
        _adController.adPlayerHeight = _adPlayerHeight;
        _adController.locale = _locale;
        [_parentViewController addChildViewController:_adController];
        [_parentViewController.view addSubview:_adController.view];
        _adController.datasource = _kIMAWebOpenerDelegate;
        [_adController loadIMAAd:adTagURL
               withContentPlayer:_player];
    }
}

- (void)removeAdController {
    self.isAllAdsCompleted = YES;
    [self.delegate allAdsCompleted];
    [self.adController removeIMAPlayer];
    self.adController = nil;
}

- (void)switchPlayer:(NSString *)playerClassName key:(NSString *)_key {
    _playerClassName = playerClassName;
    key = _key;
}

- (id<KPlayer>)createPlayerFromClassName:(NSString *)className {
    if (className) {
        Class class = NSClassFromString(className);
        
        return [(id<KPlayer>)[class alloc] initWithParentView:_parentViewController.view];
    }
    
    return nil;
}

- (void)changePlayer:(id<KPlayer>)player {
    player.delegate = _player.delegate;
    player.playerSource = _player.playerSource;
    player.duration = _player.duration;
    player.currentPlaybackTime = _player.currentPlaybackTime;
    [self removePlayer];
    _player = player;
}

- (void)changeSubtitleLanguage:(NSString *)isoCode {
    [_player changeSubtitleLanguage:isoCode];
}

- (void)removePlayer {
    if (_adController) {
        [_adController removeIMAPlayer];
    }

    [_player removePlayer];
    _adController = nil;
    _player = nil;
    _delegate = nil;
    _parentViewController = nil;
    _src = nil;
    _playerClassName = nil;
}

#pragma mark
#pragma mark Casting
- (void)setCastProvider:(KCastProvider *)castProvider {
    if (castProvider) {
        _castProvider = castProvider;
        _castProvider.internalDelegate = self;
    }
}

- (void)sendCastRecieverTextMessage:(NSString *)message {
    BOOL check = [_castProvider.castChannel sendTextMessage:message];
    if (check) {
        NSLog(@"%@", message);
    }
}

#pragma mark CastProviderInternalDelegate
- (void)startCasting:(id<KPGCMediaControlChannel>)mediaControlChannel {
    if (!_castPlayer) {
        _castPlayer = [[KChromecastPlayer alloc] initWithMediaChannel:mediaControlChannel];
        _castPlayer.delegate = self;
    }
    [_delegate player:_player eventName:@"chromecastDeviceConnected" value:nil];
//    [_castPlayer setVideoUrl:_src startPosition:self.currentPlayBackTime];
    if (self.currentPlayBackTime > 0) {
        [_castPlayer seek:self.currentPlayBackTime];
    }
}

- (void)updateCastState:(NSString *)state {
    isPlaying = _player.isPlaying;
    [_delegate player:_player eventName:state value:nil];
}

- (void)stopCasting {
    [_delegate player:_player eventName:@"chromecastDeviceDisConnected" value:nil];
    [_player setCurrentPlaybackTime:_castPlayer.currentTime];
    _castPlayer = nil;
    currentPlayerType = CurrentPlyerTypeDefault;
    [self play];
}

- (void)readyToPlay:(id<KPGCMediaControlChannel>)mediaControlChannel {
    currentPlayerType = CurrentPlyerTypeCast;
    [self.delegate player:_player
                eventName:DurationChangedKey
                    value:@(mediaControlChannel.mediaStatus.mediaInformation.streamDuration).stringValue];
    [self.delegate player:_player
                eventName:LoadedMetaDataKey
                    value:@""];
    [self.delegate player:_player eventName:CanPlayKey value:nil];
    [_delegate player:_player eventName:@"hideConnectingMessage" value:nil];
    if (isPlaying) {
        [_castPlayer play];
    }
}

- (void)castPlayerState:(NSString *)state {
    [_delegate player:_player eventName:state value:nil];
}

#pragma mark KChromecastPlayerDelegate
- (void)updateProgress:(NSTimeInterval)currentTime {
    [self.delegate player:_player
                eventName:TimeUpdateKey
                    value:@(currentTime).stringValue];
}



#pragma mark KPlayerEventsDelegate
- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event value:(NSString *)value {
    if ([event isEqualToString:CanPlayKey]) {
        isReady = YES;
        
        NSLog(@"_currentPlayBackTime::%f",_currentPlayBackTime);
        if (_backToForeground) {
            _backToForeground = NO;
            [self setCurrentPlayBackTime:_lastPosition];
            
            if (_isReleasePlayerPositionEnabled) {
                _isReleasePlayerPositionEnabled = NO;
                [self play];
            }
            
            return;
        }
        if (_currentPlayBackTime > 0.0) {
            [self.player setCurrentPlaybackTime:_currentPlayBackTime];
            _currentPlayBackTime = 0.0;
        }
    }
    
    [_delegate player:currentPlayer eventName:event value:value];
}

- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event JSON:(NSString *)jsonString {
    
    if ([event isEqualToString:AllAdsCompletedKey] || [event isEqualToString:AdsLoadErrorKey]) {
        if (self.isContentEnded) {
            [self.player.delegate player:self.player
                               eventName:EndedKey
                                   value:nil];
        }
        
        [self removeAdController];
    }
    
    [_delegate player:currentPlayer eventName:event JSON:jsonString];
}

- (void)contentCompleted:(id<KPlayer>)currentPlayer {
    self.isContentEnded = YES;
// Notify IMA SDK when content is done for post-rolls.
    if (_adController) {
        [_adController contentCompleted];
    }
    
    if (!self.adController || self.isAllAdsCompleted) {
        [self.player.delegate player:self.player
                               eventName:EndedKey
                                   value:nil];
    }
}

- (void)enableTracks:(BOOL)isEnablingTracks {
    KPLogInfo(@"disableTracksInBackground");
    
    if ([self.player respondsToSelector: @selector(enableTracks:)]) {
        [self.player enableTracks:isEnablingTracks];
    }
}

- (void)play {
    if (_backToForeground) {
        _isReleasePlayerPositionEnabled = YES;
    }
    
    if (self.isReleasePlayerPositionEnabled) {
        return;
    }
    
    if (_adController) {
        [self.adController resume];
    }
    
    if (currentPlayerType == CurrentPlyerTypeCast) {
        [_castPlayer play];
    }
    
    if (currentPlayerType == CurrentPlyerTypeDefault && [self.player respondsToSelector:@selector(play)]) {
        [self.player play];
    }
}

- (void)pause {
    if (_adController) {
        [self.adController pause];
    }
    
    if (currentPlayerType == CurrentPlyerTypeCast) {
        [_castPlayer pause];
    }
    
    if ([self.player respondsToSelector:@selector(pause)]) {
        [self.player pause];
    }
}

- (void)prepareForChangeConfiguration {
    if (_adController) {
        [self.adController removeIMAPlayer];
        _adController = nil;
    }
    
    isReady = NO;
    isSeeked = NO;
    self.isContentEnded = NO;
    self.isAllAdsCompleted = NO;
    [self.player hidePlayer];
}

- (void)dealloc {
    KPLogInfo(@"Dealloc");
}

@end
