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
    }
    return _player;
}


- (void)setSrc:(NSString *)src {
    _src = src;
    [_player setPlayerSource:[NSURL URLWithString:src]];
}

- (void)setCurrentPlayBackTime:(NSTimeInterval)currentPlayBackTime {
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
                      } else {
                          //remove IMA
                      }
                      
                  }];
    }
}


- (void)switchPlayer:(NSString *)playerClassName key:(NSString *)_key {
    _playerClassName = playerClassName;
    key = _key;
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
        [_player removePlayer];
        _player = nil;
        [self addPlayerToController:_parentViewController];
        self.src = _src;
        isSeeked = event.isSeeked;
    } else if (!currentPlayer.isKPlayer && event.canPlay) {
        if (currentTime) {
            _player.currentPlaybackTime = currentTime;
        }
        if (!isSeeked) {
            [_player play];
        }
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
