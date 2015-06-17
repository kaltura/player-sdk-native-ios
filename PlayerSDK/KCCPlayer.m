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

@implementation KCCPlayer

@synthesize delegate = _delegate;
@synthesize currentPlaybackTime = _currentPlaybackTime;
@synthesize duration = _duration;

- (instancetype)initWithParentView:(UIView *)parentView {
    self = [super init];
    self.chromecastDeviceController = [ChromecastDeviceController sharedInstance];
    self.chromecastDeviceController.delegate = self;
    
    if (self) {
        return self;
    }
    return nil;
}

- (void)didConnectToDevice:(GCKDevice *)device {
    KPLogTrace(@"didConnectToDevice");
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
        _currentPlaybackTime = currentPlaybackTime;
        [self.chromecastDeviceController.mediaControlChannel seekToTimeInterval:currentPlaybackTime];
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

/// @todo check that dealloc was called
- (void)dealloc {
    KPLogInfo(@"Dealloc");
}

@end
