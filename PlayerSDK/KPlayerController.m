//
//  KPlayerManager.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/16/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPlayerController.h"
#import "KPLog.h"

@interface KPlayerController() {
    NSString *key;
    id playerDelegate;
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
        self.player.delegate = playerDelegate;
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



- (void)switchPlayer:(NSString *)playerClassName key:(NSString *)_key {
    playerDelegate = _player.delegate;
    [_player removePlayer];
    _player = nil;
    _playerClassName = playerClassName;
    key = _key;
    [self addPlayerToView:_view];
    self.src = _src;
}
@end
