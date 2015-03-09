//
//  KALPlayer.m
//  KalPlayerSDK
//
//  Created by Eliza Sapir on 8/13/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KalturaPlayer.h"
#import "KPLog.h"
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
    BOOL shouldNotifyPlayEnded;
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
    KPLogTrace(@"Enter");
    if (self) {
        [self setCurrentPlaybackTime: [player currentPlaybackTime]];
        [self setContentURL: [player contentURL]];
    }
    KPLogTrace(@"Exit");
}

- (int)playbackState {
    return [super playbackState];
}

-(NSURL *)contentURL {
    return [super contentURL];
}

-(void)setContentURL: (NSURL *)url {
    if (self.playbackState == MPMoviePlaybackStatePlaying || self.playbackState == MPMoviePlaybackStatePaused) {
        shouldNotifyPlayEnded = NO;
        [super stop];
        super.contentURL = [url copy];
        [self play];
    } else {
        super.contentURL = [url copy];
    }
}

-(int)controlStyle {
    return [super controlStyle];
}

-(void)setControlStyle:(int)cs {
    [super setControlStyle: cs];
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
    if( !( self.playbackState == MPMoviePlaybackStatePlaying ) ) {
        [self prepareToPlay];
        [super play];
    }
    
    [self callSelectorOnDelegate: @selector(kPlayerDidPlay)];
    KPLogTrace(@"Exit");
}

- (void)pause {
    KPLogTrace(@"Enter");
    isPlayCalled = NO;
    
    if ( !( self.playbackState == MPMoviePlaybackStatePaused ) ) {
        [super pause];
    }
    
    [ self callSelectorOnDelegate: @selector(kPlayerDidPause) ];
    KPLogTrace(@"Exit");
}

- (void)stop {
    KPLogTrace(@"Enter");
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
    KPLogTrace(@"Exit");
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
    shouldNotifyPlayEnded = YES;
    NSMutableDictionary *eventsDictionary = [[NSMutableDictionary alloc] init];
    
    [eventsDictionary setObject: MPMoviePlayerLoadStateDidChangeNotification
                         forKey: @"triggerLoadPlabackEvents:"];
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
    KPLogTrace(@"Enter");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(triggerFinishPlaybackEvents:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
    NSString *loadStateName = [[NSString alloc]init];
    
    switch ( [self loadState] ) {
        case MPMovieLoadStateUnknown:
            loadStateName = @"MPMovieLoadStateUnknown";
            KPLogDebug(@"MPMovieLoadStateUnknown");
            break;
        case MPMovieLoadStatePlayable:
            loadStateName = @"canplay";
            [self triggerKPlayerEvents: @"durationchange" withValue: @{@"durationchange": [NSString stringWithFormat: @"%f", [self duration]]}];
            [self triggerKPlayerEvents: @"loadedmetadata"  withValue: @{@"loadedmetadata": @""}];
            KPLogDebug(@"MPMovieLoadStatePlayable");
            break;
        case MPMovieLoadStatePlaythroughOK:
            loadStateName = @"MPMovieLoadStatePlaythroughOK";
            KPLogDebug(@"MPMovieLoadStatePlaythroughOK");
            break;
        case MPMovieLoadStateStalled:
            loadStateName = @"stalled";
            KPLogDebug(@"MPMovieLoadStateStalled");
            break;
        default:
            break;
    }
    
    [self triggerKPlayerEvents: loadStateName withValue: nil];
    KPLogTrace(@"Exit");
}

- (void)triggerMoviePlabackEvents: (NSNotification *)note{
    KPLogTrace(@"Enter");
    NSString *playBackName = [[NSString alloc] init];
    
    
    if (isSeeking) {
        isSeeking = NO;
        playBackName = @"seeked";
        KPLogDebug(@"MPMoviePlaybackStateStopSeeking");
        //called because there is another event that will be fired
        [self triggerKPlayerEvents: playBackName withValue: nil];
    }
    
    switch ( [self playbackState] ) {
        case MPMoviePlaybackStateStopped:
            playBackName = @"stop";
            KPLogDebug(@"MPMoviePlaybackStateStopped");
            break;
        case MPMoviePlaybackStatePlaying:
            playBackName = @"";
            if( ( [self playbackState] == MPMoviePlaybackStatePlaying ) ) {
                shouldNotifyPlayEnded = YES;
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
            
            KPLogDebug(@"MPMoviePlaybackStatePlaying");
            break;
        case MPMoviePlaybackStatePaused:
            playBackName = @"";
            if ( ( [self playbackState] == MPMoviePlaybackStatePaused ) ) {
                playBackName = @"pause";
            }
            
            KPLogDebug(@"MPMoviePlaybackStatePaused");
            break;
        case MPMoviePlaybackStateInterrupted:
            playBackName = @"MPMoviePlaybackStateInterrupted";
            KPLogDebug(@"MPMoviePlaybackStateInterrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
        case MPMoviePlaybackStateSeekingBackward:
            isSeeking = YES;
            playBackName = @"seeking";
            KPLogDebug(@"MPMoviePlaybackStateSeeking");
            break;
        default:
            break;
    }
    
    [self triggerKPlayerEvents: playBackName withValue: nil];
    
    KPLogTrace(@"Exit");
}

- (void)triggerFinishPlaybackEvents:(NSNotification*)notification {
    KPLogTrace(@"Enter");
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:nil];
    NSString *finishPlayBackName = [[NSString alloc]init];
    NSNumber* reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    
    switch ( [reason intValue] ) {
        case MPMovieFinishReasonPlaybackEnded:
            finishPlayBackName = @"ended";
            KPLogDebug(@"playbackFinished. Reason: Playback Ended");
            break;
        case MPMovieFinishReasonPlaybackError:
            finishPlayBackName = @"error";
            KPLogDebug(@"playbackFinished. Reason: Playback Error");
            break;
        case MPMovieFinishReasonUserExited:
            finishPlayBackName = @"MPMovieFinishReasonUserExited";
            KPLogDebug(@"playbackFinished. Reason: User Exited");
            break;
        default:
            break;
    }
    if (shouldNotifyPlayEnded) {
        [self triggerKPlayerEvents: finishPlayBackName withValue: nil];
    }
    KPLogTrace(@"Exit");
}

- (void)triggerKPlayerEvents: (NSString *)notName withValue: (NSDictionary *)notValueDict {
    KPLogTrace(@"Enter");
    [[NSNotificationCenter defaultCenter] postNotificationName: notName object: nil userInfo: notValueDict];
    KPLogTrace(@"Exit");
}

- (void)onMovieDurationAvailable:(NSNotification *)notification {
    KPLogTrace(@"Enter");
//    [[NSNotificationCenter defaultCenter] removeObserver: self];
    KPLogTrace(@"Exit");
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
    KPLogTrace(@"Enter");
    isWideVine = NO;
    isWideVineReady = NO;
    KPLogTrace(@"Exit");
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
    KPLogTrace(@"Enter");
    WViOsApiStatus wvInitStatus = [wvSettings initializeWD: key];

    if (wvInitStatus == WViOsApiStatus_OK) {
        KPLogDebug(@"widevine was inited");
    }

    [wvSettings playMovieFromUrl: src];
    KPLogTrace(@"Exit");
}

-(void)playWV: (NSNotification *)responseUrlNotification  {
    KPLogTrace(@"Enter");
    [ self setContentURL: [ NSURL URLWithString: [ [responseUrlNotification userInfo] valueForKey: @"response_url"] ] ];
    isWideVineReady = YES;
    
    if ( isPlayCalled ) {
        [self play];
    }
    KPLogTrace(@"Exit");
}

#endif

//KALPlayer *kp = [KALPlayer new];
//[kp setDelegate: self];

@end
