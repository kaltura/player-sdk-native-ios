//
//  KPlayer.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/12/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPlayer.h"
#import "KPLog.h"
#import "WVSettings.h"

@interface KPlayer() {
    BOOL isPlayCalled;
#if !(TARGET_IPHONE_SIMULATOR)
    // WideVine Params
    BOOL isWideVine, isWideVineReady;
    WVSettings* wvSettings;
#endif
}
@property (nonatomic, strong) AVPlayerLayer *layer;
@end

@implementation KPlayer
@synthesize delegate = _delegate;
@synthesize view = _view;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        _view = [[UIView alloc] initWithFrame:frame];
        _layer = [AVPlayerLayer playerLayerWithPlayer:self];
        [_view.layer addSublayer:_layer];
        return self;
    }
    return nil;
}

- (UIView *)view {
    return _view;
}


- (NSURL *)contentURL {
    // get current asset
    AVAsset *currentPlayerAsset = self.currentItem.asset;
    // make sure the current asset is an AVURLAsset
    if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) {
        return nil;
    }
    // return the NSURL
    return [(AVURLAsset *)currentPlayerAsset URL];
}

- (void)setContentURL:(NSURL *)cs {
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:cs];
    [self replaceCurrentItemWithPlayerItem:item];
}

- (void)play {
    KPLogTrace(@"Enter");
    isPlayCalled = YES;
    
#if !(TARGET_IPHONE_SIMULATOR)
    if ( isWideVine  && !isWideVineReady ) {
        return;
    }
#endif
    KPLogDebug(@"playbackState - %ld", self.playbackState);
    if( !( self.playbackState == AVPlayerStatusReadyToPlay ) ) {
        [super play];
    }
    
    [self callSelectorOnDelegate: @selector(kPlayerDidPlay)];
    KPLogTrace(@"Exit");
}

- (void)pause {
    KPLogTrace(@"Enter");
    isPlayCalled = NO;
    
    if (!self.rate) {
        [super pause];
    }
    
    [ self callSelectorOnDelegate: @selector(kPlayerDidPause) ];
    KPLogTrace(@"Exit");
}

- (void)stop {
    KPLogTrace(@"Enter");
    isPlayCalled = NO;
    
    [super pause];
    self.rate = 0.0;
    
#if !(TARGET_IPHONE_SIMULATOR)
    // Stop WideVine
    if ( isWideVine ) {
        [wvSettings stopWV];
        isWideVine = NO;
        isWideVineReady = NO;
    }
#endif
    
    [ self callSelectorOnDelegate: @selector(kPlayerDidStop) ];
    KPLogTrace(@"Exit");
}


- (void)callSelectorOnDelegate:(SEL) selector {
    if ( _delegate && [_delegate respondsToSelector: selector] ) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_delegate performSelector: selector];
#pragma clang diagnostic pop
    }
}

- (NSTimeInterval)currentPlaybackTime {
    return CMTimeGetSeconds(self.currentTime);
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currPlaybackTime {
    [self seekToTime:(CMTime){currPlaybackTime, 1}];
}



- (double)duration {
    AVAsset *asset = self.currentItem.asset;
    return CMTimeGetSeconds(asset.duration);
}

- (void)bindPlayerEvents {
    [self addPeriodicTimeObserverForInterval:(CMTime){0.1, 100}
                                       queue:dispatch_get_main_queue()
                                  usingBlock:^(CMTime time) {
                                      
    }];
    [self addObserver:self forKeyPath:@"status" options:0 context:nil];
}

- (void)updatePlaybackProgressFromTimer:(NSTimer *)timer {
    
}

@end
