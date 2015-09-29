//
//  KPlayerManager.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/16/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPlayerController.h"
#import "KPLog.h"
#import "NSString+Utilities.h"
#import "KPIMAPlayerViewController.h"

@interface KPlayerController() <KPlayerDelegate>{
    NSString *key;
    BOOL isSeeked;
    NSTimeInterval currentDuration;
}

@property (nonatomic, strong) UIViewController *parentViewController;
@property (nonatomic, strong) KPIMAPlayerViewController *adController;
@property (nonatomic) BOOL contentEnded;
@end

@implementation KPlayerController

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
    } else if ([self.player respondsToSelector:@selector(setDRMKey:)]) {
        self.player.DRMKey = key;
    }
}

- (id<KPlayer>)player {
    if (!_player) {
        Class class = NSClassFromString(_playerClassName);
        _player = [(id<KPlayer>)[class alloc] initWithParentView:_parentViewController.view];
        _player.delegate = self;
        _player.playerSource = [NSURL URLWithString: _src];
        _player.duration = currentDuration;
    }
    return _player;
}


- (void)setSrc:(NSString *)src {
    _src = src;
    [_player setPlayerSource:[NSURL URLWithString:src]];
}

- (void)setCurrentPlayBackTime:(NSTimeInterval)currentPlayBackTime {
    _currentPlayBackTime = currentPlayBackTime;
    _player.currentPlaybackTime = currentPlayBackTime;
}

- (void)setAdTagURL:(NSString *)adTagURL {
    if (!_adController) {
        _adController = [KPIMAPlayerViewController new];
        _adController.adPlayerHeight = _adPlayerHeight;
        _adController.locale = _locale;
        [_parentViewController addChildViewController:_adController];
        [_parentViewController.view addSubview:_adController.view];
        __weak KPlayerController *weakSelf = self;
        [_adController loadIMAAd:adTagURL
               withContentPlayer:_player
                  eventsListener:^(NSDictionary *adEventParams) {
                      if (adEventParams) {
                          [weakSelf.player.delegate player:weakSelf.player
                                                 eventName:adEventParams.allKeys.firstObject
                                                      JSON:adEventParams.allValues.firstObject];
                      } else if (weakSelf.contentEnded){
                          [weakSelf.delegate allAdsCompleted];
                      } else if (!adEventParams) {
                          [weakSelf.adController removeIMAPlayer];
                      }
                      
                  }];
    }
}


- (void)switchPlayer:(NSString *)playerClassName key:(NSString *)_key {
    currentDuration = _player.duration;
    [self removePlayer];
    _playerClassName = playerClassName;
    key = _key;
}

- (void)changeSubtitleLanguage:(NSString *)isoCode {
    [_player changeSubtitleLanguage:isoCode];
}

- (void)removePlayer {
    [_player removePlayer];
    _player = nil;
    [_adController removeIMAPlayer];
    _adController = nil;
}


#pragma mark KPlayerEventsDelegate
- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event value:(NSString *)value {
    static NSTimeInterval currentTime;

    if (key && currentPlayer.isKPlayer && (event.isPlay || event.isSeeked)) {
        currentTime = _player.currentPlaybackTime;
        [self removePlayer];
        [self addPlayerToController:_parentViewController];
        self.src = _src;
        isSeeked = event.isSeeked;
        ///@todo understand why this if statment is needed
    } else if (!currentPlayer.isKPlayer && event.canPlay) {
        if (currentTime) {
            _player.currentPlaybackTime = currentTime;
        } else if (_currentPlayBackTime) {
            _player.currentPlaybackTime = _currentPlayBackTime;
        }
        ///@todo check if it's widevine player
        if (!isSeeked) {
            //[_player play];
        }
        
    } else if (event.canPlay && _currentPlayBackTime) {
        ///@todo add an optimization to show progressbar updated
        _player.currentPlaybackTime = _currentPlayBackTime;
    } else {
        [_delegate player:currentPlayer eventName:event value:value];
    }
}

- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event JSON:(NSString *)jsonString {
    [_delegate player:currentPlayer eventName:event JSON:jsonString];
}

- (void)contentCompleted:(id<KPlayer>)currentPlayer {
    self.contentEnded = YES;
    [_adController contentCompleted];
}

- (void)dealloc {
    KPLogInfo(@"Dealloc");
}

@end
