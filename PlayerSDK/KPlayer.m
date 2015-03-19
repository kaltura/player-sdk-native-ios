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

static NSString *PlayKey = @"play";
static NSString *PauseKey = @"pause";
static NSString *DurationChangedKey = @"durationchange";
static NSString *LoadedMetaDataKey = @"loadedmetadata";
static NSString *TimeUpdateKey = @"timeupdate";
static NSString *ProgressKey = @"progress";
static NSString *EndedKey = @"ended";
static NSString *SeekedKey = @"seeked";
static NSString *CanPlayKey = @"canplay";


static NSString *RateKeyPath = @"rate";
static NSString *StatusKeyPath = @"status";

@interface KPlayer() 
@property (nonatomic, strong) AVPlayerLayer *layer;
@end

@implementation KPlayer
@synthesize delegate = _delegate;
@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize duration = _duration;

- (instancetype)initWithParentView:(UIView *)parentView {
    self = [super init];
    if (self) {
        _layer = [AVPlayerLayer playerLayerWithPlayer:self];
        _layer.frame = parentView.frame;
        [parentView.layer addSublayer:_layer];
        
        [self addObserver:self
               forKeyPath:RateKeyPath
                  options:0
                  context:nil];
        [self addObserver:self
               forKeyPath:StatusKeyPath
                  options:0
                  context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(videoEnded)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        __weak KPlayer *weakSelf = self;
        [self addPeriodicTimeObserverForInterval:CMTimeMake(20, 100)
                                           queue:dispatch_get_main_queue()
                                      usingBlock:^(CMTime time) {
                                          [weakSelf.delegate eventName:TimeUpdateKey
                                                                 value:@(CMTimeGetSeconds(time)).stringValue];
//                                          [weakSelf.delegate eventName:ProgressKey
//                                                                 value:@(CMTimeGetSeconds(time) / weakSelf.duration).stringValue];
        }];
        
        return self;
    }
    return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqual:RateKeyPath]) {
        if (self.rate) {
            [self.delegate eventName:@"play" value:nil];
        } else {
            [self.delegate eventName:@"pause" value:nil];
        }
    } else if (StatusKeyPath) {
        switch (self.status) {
            case AVPlayerStatusFailed:
                
                break;
            case AVPlayerStatusReadyToPlay:
                [self.delegate eventName:DurationChangedKey value:@(self.duration).stringValue];
                [self.delegate eventName:LoadedMetaDataKey value:@""];
                [self.delegate eventName:CanPlayKey value:nil];
                break;
            case AVPlayerStatusUnknown:
                break;
        }
    }
}

- (void)videoEnded {
    [self.delegate eventName:EndedKey value:nil];
}

- (void)setPlayerSource:(NSURL *)playerSource {
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:playerSource];
    [self replaceCurrentItemWithPlayerItem:item];
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
    [self seekToTime:CMTimeMake(currentPlaybackTime, 1000)
     toleranceBefore:kCMTimeZero
      toleranceAfter:kCMTimeZero
   completionHandler:^(BOOL finished) {
       [weakSelf.delegate eventName:SeekedKey value:nil];
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

@end
