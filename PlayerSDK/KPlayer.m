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




static NSString *RateKeyPath = @"rate";
static NSString *StatusKeyPath = @"status";

@interface KPlayer() {
    MPVolumeView *volumeView;
    NSArray *prevAirPlayBtnPositionArr;
    id observer;
}
@property (nonatomic, strong) AVPlayerLayer *layer;
@property (nonatomic, strong) UIView *parentView;
@end

@implementation KPlayer
@synthesize delegate = _delegate;
@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize duration = _duration;

- (instancetype)initWithParentView:(UIView *)parentView {
    self = [super init];
    if (self) {
        _layer = [AVPlayerLayer playerLayerWithPlayer:self];
        _layer.frame = (CGRect){CGPointZero, parentView.frame.size};
        _layer.backgroundColor = [UIColor blackColor].CGColor;
        _parentView = parentView;
        if (parentView.subviews.count) {
            UIWebView *wv = parentView.subviews.lastObject;
            [parentView.subviews.lastObject removeFromSuperview];
            [parentView.layer.sublayers.firstObject removeFromSuperlayer];
            [parentView.layer addSublayer:_layer];
            [parentView addSubview:wv];
        } else {
            [parentView.layer addSublayer:_layer];
        }
        
        [self addObserver:self
               forKeyPath:RateKeyPath
                  options:0
                  context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(videoEnded)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        __weak KPlayer *weakSelf = self;
        observer = [self addPeriodicTimeObserverForInterval:CMTimeMake(20, 100)
                                                      queue:dispatch_get_main_queue()
                                                 usingBlock:^(CMTime time) {
                                          [weakSelf.delegate player:weakSelf eventName:TimeUpdateKey
                                                                 value:@(CMTimeGetSeconds(time)).stringValue];
//                                          [weakSelf.delegate eventName:ProgressKey
//                                                                 value:@(CMTimeGetSeconds(time) / weakSelf.duration).stringValue];
        }];
        self.allowsExternalPlayback = YES;
        self.usesExternalPlaybackWhileExternalScreenIsActive = YES;
        return self;
    }
    return nil;
}

- (BOOL)isKPlayer {
    return [self isMemberOfClass:[KPlayer class]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqual:RateKeyPath]) {
        if (self.rate) {
            [self.delegate player:self eventName:PlayKey value:nil];
        } else {
            [self.delegate player:self eventName:PauseKey value:nil];
        }
    } else if ([keyPath isEqualToString:StatusKeyPath]) {
        switch (self.status) {
            case AVPlayerStatusFailed:
                
                break;
            case AVPlayerStatusReadyToPlay:
                [self.delegate player:self eventName:DurationChangedKey value:@(self.duration).stringValue];
                [self.delegate player:self eventName:LoadedMetaDataKey value:@""];
                [self.delegate player:self eventName:CanPlayKey value:nil];
                break;
            case AVPlayerStatusUnknown:
                break;
        }
    }
}


- (void)videoEnded {
    [_delegate contentCompleted:self];
}

- (void)setPlayerSource:(NSURL *)playerSource {
    KPLogInfo(@"%@", playerSource);
    if (self.currentItem) {
        [self removeObserver:self forKeyPath:RateKeyPath context:nil];
        [self.currentItem removeObserver:self forKeyPath:StatusKeyPath context:nil];
    }
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:playerSource];
    [item addObserver:self
           forKeyPath:StatusKeyPath
              options:0
              context:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self replaceCurrentItemWithPlayerItem:item];
    });
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

- (NSTimeInterval)duration {
    AVPlayerItem *item = self.currentItem;
    return CMTimeGetSeconds(item.asset.duration);
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
    _currentPlaybackTime = currentPlaybackTime;
    __weak KPlayer *weakSelf = self;
    [self seekToTime:CMTimeMake(currentPlaybackTime, 1)
     toleranceBefore:kCMTimeZero
      toleranceAfter:kCMTimeZero
   completionHandler:^(BOOL finished) {
       [weakSelf.delegate player:self eventName:SeekedKey value:nil];
   }];
}

- (NSTimeInterval)currentPlaybackTime {
    return _currentPlaybackTime;
}

- (void)play {
    if (!self.rate) {
        [super play];
    }
}

- (void)pause {
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
        KPLogError(@"Not registered to Rate key");
    }
    [self.currentItem removeObserver:self forKeyPath:StatusKeyPath context:nil];
    [_layer removeFromSuperlayer];
    _layer = nil;
    self.delegate = nil;
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

-(void)hideNativeAirPlayButton {
    KPLogTrace(@"Enter");
    if ( !volumeView.hidden ) {
        volumeView.hidden = YES;
    }
    KPLogTrace(@"Exit");
}

- (void)dealloc {
    KPLogInfo(@"Dealloc");
}

@end
