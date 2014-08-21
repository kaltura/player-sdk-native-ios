//
//  KALPlayer.m
//  KalPlayerSDK
//
//  Created by Eliza Sapir on 8/13/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KALPlayer.h"

@implementation KALPlayer {
    // Player Params
    BOOL isSeeking;
    BOOL isFullScreen, isPlaying, isResumePlayer, isPlayCalled;
    CGRect originalViewControllerFrame;
    CGAffineTransform fullScreenPlayerTransform;
    UIDeviceOrientation prevOrientation, deviceOrientation;
    NSString *playerSource;
    NSMutableDictionary *appConfigDict;
    BOOL openFullScreen;
    UIButton *btn;
    BOOL isCloseFullScreenByTap;
    // AirPlay Params
    MPVolumeView *volumeView;
    NSArray *prevAirPlayBtnPositionArr;
    
    BOOL isJsCallbackReady;
    NSMutableDictionary *kPlayerEventsDict;
    NSMutableDictionary *kPlayerEvaluatedDict;
    
#if !(TARGET_IPHONE_SIMULATOR)
    // WideVine Params
    BOOL isWideVine, isWideVineReady;
    WVSettings* wvSettings;
#endif
}

@synthesize delegate;
@synthesize currentPlaybackTime;
@synthesize view;
@synthesize controlStyle;
@synthesize playbackState;
@synthesize loadState;
@synthesize isPreparedToPlay;
@synthesize contentURL;

- (void) copyParamsFromPlayer:(id<KalturaPlayer>) player {
    if (self) {
        if ( [self isPreparedToPlay] ) {
            self.currentPlaybackTime = player.currentPlaybackTime;
        }
        
        [self setContentURL: [player contentURL]];
    }
}

-(NSURL *)contentURL {
    return super.contentURL;
}
-(void)setContentURL:(NSURL *)cs {
    super.contentURL = [cs copy];
}

-(int)controlStyle {
    return [super controlStyle];
}

-(void)setControlStyle:(int)cs {
    [super setControlStyle:cs];
}

- (void)play {
    NSLog( @"Play Player Enter" );
    
    isPlayCalled = YES;
    
#if !(TARGET_IPHONE_SIMULATOR)
    if ( isWideVine  && !isWideVineReady ) {
        return;
    }
#endif
    
    if( !( self.playbackState == MPMoviePlaybackStatePlaying ) ) {
        [self prepareToPlay];
        [super play];
    }
    
    [ self callSelectorOnDelegate: @selector(kPlayerDidPlay) ];
    
    NSLog( @"Play Player Exit" );
}

- (void)pause {
    NSLog(@"Pause Player Enter");
    
    isPlayCalled = NO;
    
    if ( !( self.playbackState == MPMoviePlaybackStatePaused ) ) {
        [super pause];
    }
    
    [ self callSelectorOnDelegate: @selector(kPlayerDidPause) ];
    
    NSLog(@"Pause Player Exit");
}

- (void)stop {
    NSLog(@"Stop Player Enter");
    
    [super stop];
    isPlaying = NO;
    isPlayCalled = NO;
    
#if !(TARGET_IPHONE_SIMULATOR)
    // Stop WideVine
    if ( isWideVine ) {
        [wvSettings stopWV];
        isWideVine = NO;
        isWideVineReady = NO;
    }
#endif
    
    [ self callSelectorOnDelegate: @selector(kPlayerDidStop) ];
    
    NSLog(@"Stop Player Exit");
}

- (void)callSelectorOnDelegate:(SEL) selector {
    if ( delegate && [delegate respondsToSelector: selector] ) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [delegate performSelector: selector];
#pragma clang diagnostic pop
    }
}

- (id)view {
    return [super view];
}

- (double)currentPlaybackTime {
    return [super currentPlaybackTime];
}


- (int)playbackState {
    return [super playbackState];
}

- (int)loadState {
    return [super loadState];
}

- (void)prepareToPlay {
    [super prepareToPlay];
}

- (BOOL)isPreparedToPlay {
    return [super isPreparedToPlay];
}


- (double)playableDuration {
    return [super playableDuration];
}

- (double)duration {
    return [super duration];
}

//KALPlayer *kp = [KALPlayer new];
//[kp setDelegate: self];



@end
