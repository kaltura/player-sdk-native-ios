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

@interface KPlayerFactory() <KPlayerDelegate>{
    NSString *key;
    BOOL isSeeked;
    BOOL isReady;
}

@property (nonatomic, strong) UIViewController *parentViewController;
@property (nonatomic) BOOL isContentEnded;
@property (nonatomic) BOOL isAllAdsCompleted;

@end

@implementation KPlayerFactory
@synthesize currentPlayBackTime = _currentPlayBackTime;

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
    
    NSURL* url = [NSURL URLWithString:_src];
    if ([self isWVM]) {
        // May fail if content is DRM protected. We'll try again if/when we get a licenseUri.
        KPLogDebug(@"Content (%@) is WVM, waiting for license uri", url);
    } else {
        [self.player setPlayerSource:url];
    }
}

-(void)setLicenseUri:(NSString*)licenseUri {
    
    if (![self isWVM]) {
        return;
    }
    
    _licenseUri = licenseUri;
    
    [WidevineClassicCDM playAsset:_src withLicenseUri:_licenseUri readyToPlay:^(NSString *playbackURL) {
        if (!playbackURL) {
            KPLogError(@"Got nil playback URL, can't play");
        } else {
            NSURL* url = [NSURL URLWithString:playbackURL];
            [self.player setPlayerSource:url];
        }
    }];
}

- (BOOL)isWVM {
    if (_src != nil) {
        return [[NSURL URLWithString:_src].pathExtension hasSuffix:@"wvm"];
    }
    
    return NO;
}

- (NSTimeInterval)currentPlayBackTime {
    return _player.currentPlaybackTime;
}

- (void)setCurrentPlayBackTime:(NSTimeInterval)currentPlayBackTime {
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


#pragma mark KPlayerEventsDelegate
- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event value:(NSString *)value {
    if ([event isEqualToString:CanPlayKey]) {
        isReady = YES;
        
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
    if (self.isReleasePlayerPositionEnabled) {
        return;
    }
    
    if (_adController) {
        [self.adController resume];
    }
    
    if ([self.player respondsToSelector:@selector(play)]) {
        [self.player play];
    }
}

- (void)pause {
    if (_adController) {
        [self.adController pause];
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
    
    [self.player hidePlayer];
}

- (void)dealloc {
    KPLogInfo(@"Dealloc");
}

@end
