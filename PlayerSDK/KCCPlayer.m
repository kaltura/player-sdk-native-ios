//
//  CCKPlayer.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 6/14/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KCCPlayer.h"
#import "KPLog.h"
#import <GoogleCast/GoogleCast.h>

@interface KCCPlayer()

/* A timer to trigger a callback to update the times/slider position. */
@property(weak, nonatomic) NSTimer* updateStreamTimer;

@end

@implementation KCCPlayer

@synthesize delegate = _delegate;
@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize duration = _duration;

- (instancetype)initWithParentView:(UIView *)parentView {
    self = [super init];
    self.chromecastDeviceController = [ChromecastDeviceController sharedInstance];
    self.chromecastDeviceController.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(castMediaStatusChanged:)
                                                 name: @"castMediaStatusChange"
                                               object: nil];
    
    // Start the timer
    if (self.updateStreamTimer) {
        [self.updateStreamTimer invalidate];
        self.updateStreamTimer = nil;
    }
    
    self.updateStreamTimer =
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(updateProgressFromCast:)
                                   userInfo:nil
                                    repeats:YES];
    
    if (self) {
        return self;
    }
    return nil;
}

///@todo remove the timer when view disappears
//- (void)viewWillDisappear:(BOOL)animated {
//    // I think we can safely stop the timer here
//    [self.updateStreamTimer invalidate];
//    self.updateStreamTimer = nil;

- (void) castMediaStatusChanged:(NSNotification *)notification {
    KPLogTrace(@"Enter");
    
    switch (((ChromecastDeviceController*)notification.object).playerState) {
        case GCKMediaPlayerStateBuffering:
        case GCKMediaPlayerStatePlaying:
            [_delegate player:self eventName:@"play" value:nil];
            break;
        case GCKMediaPlayerStateUnknown:
        case GCKMediaPlayerStatePaused:
            [_delegate player:self eventName:@"pause" value:nil];
            break;

        default:
            KPLogDebug(@"castMediaStatusChanged: %d", ((ChromecastDeviceController*)notification.object).playerState);
            break;
    }
}

- (void)updateProgressFromCast:(NSTimer*)timer {
//    if (!_readyToShowInterface)
//        return;
    
//    if (self.chromecastDeviceController.playerState != GCKMediaPlayerStateBuffering) {
//        [self.castActivityIndicator stopAnimating];
//    } else {
//        [self.castActivityIndicator startAnimating];
//    }
    
//    if (([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) &&
//            self.chromecastDeviceController.streamDuration > 0) {
//        _lastKnownTime = self.chromecastDeviceController.streamPosition;
//        self.currTime.text = [self getFormattedTime:_castDeviceController.streamPosition];
//        self.totalTime.text = [self getFormattedTime:_castDeviceController.streamDuration];
//        [self.slider
//         setValue:(self.chromecastDeviceController.streamPosition / self.chromecastDeviceController.streamDuration)
//         animated:YES];
//        [self triggerKPlayerEvents: @"timeupdate"
//                         withValue: @{@"timeupdate": [NSString stringWithFormat:@"%f", [self currentPlaybackTime]]}];
    _currentPlaybackTime = _chromecastDeviceController.streamPosition;
        [_delegate player:self eventName:@"timeupdate" value:[NSString stringWithFormat:@"%f", self.currentPlaybackTime]];
    
//        [weakSelf.delegate player:weakSelf eventName:TimeUpdateKey
//                            value:@(CMTimeGetSeconds(time)).stringValue];
    
//    [self updateToolbarControls];
}

- (void)didConnectToDevice:(GCKDevice *)device {
    KPLogTrace(@"didConnectToDevice");
    [_delegate player:self eventName:@"chromecastDeviceConnected" value:nil];
    //    [self triggerEventsJavaScript: @"chromecastDeviceConnected" WithValue: nil];
}

- (void)setPlayerSource:(NSURL *)playerSource {
    KPLogInfo(@"playerSource: %@", playerSource);
    
    if (self.chromecastDeviceController.mediaInformation) {
        [self.chromecastDeviceController clearPreviousSession];
    }
    
    ///@todo replace null with relevant values
    GCKMediaInformation *mediaInformation =
    [[GCKMediaInformation alloc] initWithContentID: [playerSource absoluteString]
                                        streamType: GCKMediaStreamTypeNone
                                       contentType: self.chromecastDeviceController.mediaInformation.contentType
                                          metadata: self.chromecastDeviceController.mediaInformation.metadata
                                    streamDuration: self.chromecastDeviceController.mediaInformation.streamDuration
                                        customData: nil];
    [self.chromecastDeviceController setMediaInformation: mediaInformation];
    [self.chromecastDeviceController.mediaControlChannel loadMedia:mediaInformation];
}

- (NSURL *)playerSource {
    NSURL *playerSrc = [NSURL URLWithString:self.chromecastDeviceController.mediaInformation.contentID];
    KPLogDebug(@"playerSrc: %@", playerSrc);
    
    if (!playerSrc) {
        return nil;
    }
    
    return playerSrc;
}

- (NSTimeInterval)duration {
    return self.chromecastDeviceController.mediaInformation.streamDuration;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
    if (isnan(self.duration) || currentPlaybackTime < self.duration) {
        _currentPlaybackTime = self.chromecastDeviceController.streamPosition;
//        [self.chromecastDeviceController setPlaybackPercent:<#(float)#>]
        [self.chromecastDeviceController.mediaControlChannel seekToTimeInterval:self.chromecastDeviceController.streamPosition];
        [_delegate player:self eventName:SeekedKey value:nil];
    }
}

- (NSTimeInterval)currentPlaybackTime {
    return _currentPlaybackTime;
}

- (void)play {
    BOOL playing = (self.chromecastDeviceController.playerState == GCKMediaPlayerStatePlaying
                    || self.chromecastDeviceController.playerState == GCKMediaPlayerStateBuffering);
    
    if (self.chromecastDeviceController.mediaControlChannel && !playing) {
        [self.chromecastDeviceController.mediaControlChannel play];
    }
}

- (void)pause {
    BOOL paused = (self.chromecastDeviceController.playerState == GCKMediaPlayerStatePaused
                    || self.chromecastDeviceController.playerState == GCKMediaPlayerStateUnknown);
    if (self.chromecastDeviceController.mediaControlChannel && !paused) {
        [self.chromecastDeviceController.mediaControlChannel pause];
    }
}

- (void)removePlayer {
    [self pause];
    [self.chromecastDeviceController clearPreviousSession];
    self.chromecastDeviceController = nil;
    self.delegate = nil;
}
//
//- (void) mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel {
//    if (mediaControlChannel.mediaStatus == self.chromecastDeviceController.mediaControlChannel.mediaStatus) {
//        <#statements#>
//    }
//}

- (BOOL)isKPlayer {
    return nil;
}

/// @todo check that dealloc was called
- (void)dealloc {
    KPLogInfo(@"Dealloc");
}

@end
