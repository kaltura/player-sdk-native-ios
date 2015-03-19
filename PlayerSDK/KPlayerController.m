//
//  KPlayerManager.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/16/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPlayerController.h"

@interface KPlayerController()

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
    Class class = NSClassFromString(_playerClassName);
    _player = [(id<KPlayer>)[class alloc] initWithParentView:parentView];
    if (_player) {
        
    } else {
        ///@todo error
    }
}

- (void)setWideVineKey:(NSString *)wideVineKey {
    
}

- (void)setSrc:(NSString *)src {
    [_player setPlayerSource:[NSURL URLWithString:src]];
}

- (void)setCurrentPlayBackTime:(NSTimeInterval)currentPlayBackTime {
    _player.currentPlaybackTime = currentPlayBackTime;
}
@end
