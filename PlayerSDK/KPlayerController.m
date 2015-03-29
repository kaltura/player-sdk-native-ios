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

@interface KPlayerController() <KPlayerEventsDelegate>{
    NSString *key;
    id playerDelegate;
    BOOL isSeeked;
}

@property (nonatomic, strong) UIView *view;
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


- (void)addPlayerToView:(UIView *)parentView {
    _view = parentView;
    if (!self.player) {
        KPLogError(@"%@", @"NO PLAYER CREATED");
    } else if ([self.player respondsToSelector:@selector(setDRMKey:)]) {
        self.player.DRMKey = key;
        self.player.delegate = self;
    }
}

- (id<KPlayer>)player {
    if (!_player) {
        Class class = NSClassFromString(_playerClassName);
        _player = [(id<KPlayer>)[class alloc] initWithParentView:_view];
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
    
}



- (void)switchPlayer:(NSString *)playerClassName key:(NSString *)_key {
    playerDelegate = _player.delegate;
    _player.delegate = self;
    _playerClassName = playerClassName;
    key = _key;
}

#pragma mark KPlayerEventsDelegate
- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event value:(NSString *)value {
    static NSTimeInterval currentTime;
    if (currentPlayer.isKPlayer && (event.isPlay || event.isSeeked)) {
        currentTime = _player.currentPlaybackTime;
        [_player removePlayer];
        _player = nil;
        [self addPlayerToView:_view];
        self.src = _src;
        isSeeked = event.isSeeked;
    }
    if (!currentPlayer.isKPlayer && event.canPlay) {
        if (currentTime) {
            _player.currentPlaybackTime = currentTime;
        }
        if (!isSeeked) {
            [_player play];
        }
        self.player.delegate = playerDelegate;
    }
    if (!currentPlayer.isKPlayer && (event.isMetadata || event.isDurationChanged || event.isPlay || event.isSeeked)) {
        [playerDelegate player:currentPlayer eventName:event value:value];
    }
}
@end
