//
//  KALPlayer.m
//  KalPlayerSDK
//
//  Created by Eliza Sapir on 8/13/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KalturaPlayer.h"
#if !(TARGET_IPHONE_SIMULATOR)
#import "WVSettings.h"
#import "WViPhoneAPI.h"
#endif

@implementation KalturaPlayer {
    // Player Params
    BOOL isSeeking;
    BOOL isPlayCalled;
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
@synthesize view;
@synthesize controlStyle;
@synthesize playbackState;
@synthesize loadState;
@synthesize isPreparedToPlay;
@synthesize contentURL;

- (void) copyParamsFromPlayer:(id<KalturaPlayer>) player {
    NSLog(@"copyParamsFromPlayer Enter");
    
    if (self) {
        [self setCurrentPlaybackTime: [player currentPlaybackTime]];
        [self setContentURL: [player contentURL]];
    }
    
    NSLog(@"copyParamsFromPlayer Exit");
}

- (int)playbackState {
    return [super playbackState];
}

-(NSURL *)contentURL {
    return [super contentURL];
}

-(void)setContentURL: (NSURL *)url {
    super.contentURL = [url copy];
}

-(int)controlStyle {
    return [super controlStyle];
}

-(void)setControlStyle:(int)cs {
    [super setControlStyle: cs];
}

- (void)play {
    NSLog(@"play Enter");
    
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
    
    [self callSelectorOnDelegate: @selector(kPlayerDidPlay)];
    
    NSLog(@"play Exit");
}

- (void)pause {
    NSLog(@"pause Enter");
    
    isPlayCalled = NO;
    
    if ( !( self.playbackState == MPMoviePlaybackStatePaused ) ) {
        [super pause];
    }
    
    [ self callSelectorOnDelegate: @selector(kPlayerDidPause) ];
    
    NSLog(@"pause Exit");
}

- (void)stop {
    NSLog(@"stop Enter");
    
    isPlayCalled = NO;
    
    [super stop];
    
#if !(TARGET_IPHONE_SIMULATOR)
    // Stop WideVine
    if ( isWideVine ) {
        [wvSettings stopWV];
        isWideVine = NO;
        isWideVineReady = NO;
    }
#endif
    
    [ self callSelectorOnDelegate: @selector(kPlayerDidStop) ];
    
    NSLog(@"stop Exit");
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

- (NSTimeInterval)currentPlaybackTime {
    return [super currentPlaybackTime];
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currPlaybackTime {
    [super setCurrentPlaybackTime: currPlaybackTime];
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

- (void)bindPlayerEvents {
    NSMutableDictionary *eventsDictionary = [[NSMutableDictionary alloc] init];
    
    [eventsDictionary setObject: MPMoviePlayerLoadStateDidChangeNotification
                         forKey: @"triggerLoadPlabackEvents:"];
    [eventsDictionary setObject: MPMoviePlayerPlaybackDidFinishNotification
                         forKey: @"triggerFinishPlabackEvents:"];
    [eventsDictionary setObject: MPMoviePlayerPlaybackStateDidChangeNotification
                         forKey: @"triggerMoviePlabackEvents:"];
    [eventsDictionary setObject: MPMoviePlayerTimedMetadataUpdatedNotification
                         forKey: @"metadataUpdate:"];
    [eventsDictionary setObject: MPMovieDurationAvailableNotification
                         forKey: @"onMovieDurationAvailable:"];
    
    for (id functionName in eventsDictionary){
        id event = [eventsDictionary objectForKey: functionName];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: NSSelectorFromString(functionName)
                                                     name: event
                                                   object: self];
    }
    
#if !(TARGET_IPHONE_SIMULATOR)
    [self initWideVineParams];
#endif
}

- (void)triggerLoadPlabackEvents: (NSNotification *)note{
    NSLog(@"triggerLoadPlabackEvents Enter");
    
    NSString *loadStateName = [[NSString alloc]init];
    
    switch ( [self loadState] ) {
        case MPMovieLoadStateUnknown:
            loadStateName = @"MPMovieLoadStateUnknown";
            NSLog(@"MPMovieLoadStateUnknown");
            break;
        case MPMovieLoadStatePlayable:
            loadStateName = @"canplay";
            [self triggerKPlayerEvents: @"durationchange" withValue: @{@"durationchange": [NSString stringWithFormat: @"%f", [self duration]]}];
            [self triggerKPlayerEvents: @"loadedmetadata"  withValue: @{@"loadedmetadata": @""}];
            NSLog(@"MPMovieLoadStatePlayable");
            break;
        case MPMovieLoadStatePlaythroughOK:
            loadStateName = @"MPMovieLoadStatePlaythroughOK";
            NSLog(@"MPMovieLoadStatePlaythroughOK");
            break;
        case MPMovieLoadStateStalled:
            loadStateName = @"stalled";
            NSLog(@"MPMovieLoadStateStalled");
            break;
        default:
            break;
    }
    
    [self triggerKPlayerEvents: loadStateName withValue: nil];
    
    NSLog(@"triggerLoadPlabackEvents Exit");
}

- (void)triggerMoviePlabackEvents: (NSNotification *)note{
    NSLog(@"triggerMoviePlabackEvents Enter");
    
    NSString *playBackName = [[NSString alloc] init];
    
    
    if (isSeeking) {
        isSeeking = NO;
        playBackName = @"seeked";
        NSLog(@"MPMoviePlaybackStateStopSeeking");
        //called because there is another event that will be fired
        [self triggerKPlayerEvents: playBackName withValue: nil];
    }
    
    switch ( [self playbackState] ) {
        case MPMoviePlaybackStateStopped:
            playBackName = @"stop";
            NSLog(@"MPMoviePlaybackStateStopped");
            break;
        case MPMoviePlaybackStatePlaying:
            playBackName = @"";
            if( ( [self playbackState] == MPMoviePlaybackStatePlaying ) ) {
                playBackName = @"play";
                [NSTimer scheduledTimerWithTimeInterval: .2
                                                 target: self
                                               selector: @selector(sendCurrentTime:)
                                               userInfo: nil
                                                repeats: YES];
                [NSTimer scheduledTimerWithTimeInterval: 1
                                                 target: self
                                               selector: @selector(updatePlaybackProgressFromTimer:)
                                               userInfo: nil
                                                repeats: YES];
            }
            
            NSLog(@"MPMoviePlaybackStatePlaying");
            break;
        case MPMoviePlaybackStatePaused:
            playBackName = @"";
            if ( ( [self playbackState] == MPMoviePlaybackStatePaused ) ) {
                playBackName = @"pause";
            }
            
            NSLog(@"MPMoviePlaybackStatePaused");
            break;
        case MPMoviePlaybackStateInterrupted:
            playBackName = @"MPMoviePlaybackStateInterrupted";
            NSLog(@"MPMoviePlaybackStateInterrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
        case MPMoviePlaybackStateSeekingBackward:
            isSeeking = YES;
            playBackName = @"seeking";
            NSLog(@"MPMoviePlaybackStateSeeking");
            break;
        default:
            break;
    }
    
    [self triggerKPlayerEvents: playBackName withValue: nil];
    
    NSLog(@"triggerMoviePlabackEvents Exit");
}

- (void)triggerFinishPlabackEvents:(NSNotification*)notification {
    NSLog(@"triggerFinishPlabackEvents Enter");
    
    NSString *finishPlayBackName = [[NSString alloc]init];
    NSNumber* reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    
    switch ( [reason intValue] ) {
        case MPMovieFinishReasonPlaybackEnded:
            finishPlayBackName = @"ended";
            NSLog(@"playbackFinished. Reason: Playback Ended");
            break;
        case MPMovieFinishReasonPlaybackError:
            finishPlayBackName = @"error";
            NSLog(@"playbackFinished. Reason: Playback Error");
            break;
        case MPMovieFinishReasonUserExited:
            finishPlayBackName = @"MPMovieFinishReasonUserExited";
            NSLog(@"playbackFinished. Reason: User Exited");
            break;
        default:
            break;
    }
    
    [self triggerKPlayerEvents: finishPlayBackName withValue: nil];
    
    NSLog(@"triggerFinishPlabackEvents Exit");
}

- (void)triggerKPlayerEvents: (NSString *)notName withValue: (NSDictionary *)notValueDict {
    NSLog(@"triggerKPlayerEvents Enter");
    
    [[NSNotificationCenter defaultCenter] postNotificationName: notName object: nil userInfo: notValueDict];
    
    NSLog(@"triggerKPlayerEvents Exit");
}

- (void)onMovieDurationAvailable:(NSNotification *)notification {
    NSLog(@"onMovieDurationAvailable Enter");
    
//    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    NSLog(@"onMovieDurationAvailable Exit");
}

- (void)sendCurrentTime:(NSTimer *)timer {
    if ( ( [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive )
        && ( [self playbackState] == MPMoviePlaybackStatePlaying ) ) {
        [self triggerKPlayerEvents: @"timeupdate"
                         withValue: @{@"timeupdate": [NSString stringWithFormat:@"%f", [self currentPlaybackTime]]}];
    }
}

- (void)updatePlaybackProgressFromTimer:(NSTimer *)timer {
    if ( ( [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive )
        && ( [self playbackState] == MPMoviePlaybackStatePlaying ) ) {
        CGFloat progress = [self playableDuration] / [self duration];
        [self triggerKPlayerEvents: @"progress"
                         withValue: @{@"progress": [NSString stringWithFormat:@"%f", progress]}];
    }
}

#pragma mark - WideVine Methods
#if !(TARGET_IPHONE_SIMULATOR)

- (void)initWideVineParams {
    NSLog(@"initWideVineParams Enter");
    
    isWideVine = NO;
    isWideVineReady = NO;
    
    NSLog(@"initWideVineParams Exit");
}

- (void)setWideVideConfigurations {
    wvSettings = [[WVSettings alloc] init];
    isWideVine = YES;
    [ [NSNotificationCenter defaultCenter] addObserver: self
                                              selector: @selector(playWV:)
                                                  name: @"wvResponseUrlNotification"
                                                object: nil ];
}

- (void) initWV: (NSString *)src andKey: (NSString *)key {
    NSLog(@"initWV Enter");

    WViOsApiStatus *wvInitStatus = [wvSettings initializeWD: key];

    if (wvInitStatus == WViOsApiStatus_OK) {
        NSLog(@"widevine was inited");
    }

    [wvSettings playMovieFromUrl: src];

    NSLog(@"initWV Exit");
}

-(void)playWV: (NSNotification *)responseUrlNotification  {
    NSLog(@"playWV Exit");
    
    [ self setContentURL: [ NSURL URLWithString: [ [responseUrlNotification userInfo] valueForKey: @"response_url"] ] ];
    isWideVineReady = YES;
    
    if ( isPlayCalled ) {
        [self play];
    }
    
    NSLog(@"playWV Exit");
}

#endif

//KALPlayer *kp = [KALPlayer new];
//[kp setDelegate: self];



@end
