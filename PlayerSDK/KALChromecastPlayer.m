//
//  KALChromecastPlayer.m
//  PlayerSDK
//
//  Created by Eliza Sapir on 5/12/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KALChromecastPlayer.h"

@implementation KALChromecastPlayer {
    ChromecastDeviceController *chromecastDeviceController;
    NSURL *ccContentURL;
}

@synthesize delegate;
@synthesize view;
@synthesize playbackState;
@synthesize loadState;
@synthesize isPreparedToPlay;

- (void)copyParamsFromPlayer:(id<KalturaPlayer>) player {
    NSLog(@"copyParamsFromPlayer Enter");
    
    if (self) {
        chromecastDeviceController = (ChromecastDeviceController *)[KalPlayerViewController sharedChromecastDeviceController];
        
//        if ( [self isPreparedToPlay] ) {
        [self setCurrentPlaybackTime: [player getCurrentPlaybackTime]];
//            self.currentPlaybackTime = [player currentPlaybackTime];
//        }
        
        [self setContentURL: [player contentURL]];
    }
    
    NSLog(@"copyParamsFromPlayer Exit");
}

- (int)playbackState {
    return [chromecastDeviceController playerState];
}

- (NSURL *)contentURL {
    return ccContentURL;
}

- (void)setContentURL:(NSURL *)url {
    ccContentURL = url;
    [chromecastDeviceController loadMedia: url
                             thumbnailURL: nil
                                    title: @""
                                 subtitle: @""
                                 mimeType: @""
                                startTime: [self getCurrentPlaybackTime]
                                 autoPlay: YES];
}

-(void)play {
    NSLog(@"play Enter");
    
    [chromecastDeviceController pauseCastMedia: NO];
    
    NSLog(@"play Exit");
}

-(void)pause {
    NSLog(@"pause Enter");
    
    [chromecastDeviceController pauseCastMedia: YES];
    
    NSLog(@"pause Exit");
}

-(void)stop {
    NSLog(@"stop Enter");
    
    [chromecastDeviceController stopCastMedia];
    
    NSLog(@"stop Exit");
}

- (double)playableDuration {
    return [chromecastDeviceController streamDuration];
}

- (double)duration {
    return [chromecastDeviceController streamPosition];
}

- (double)getCurrentPlaybackTime {
    return [self getCurrentTime];
}

- (CGFloat)getCurrentTime {
//    if ( [self isPreparedToPlay] ) {
        [chromecastDeviceController updateStatsFromDevice];
        
        return [chromecastDeviceController streamPosition];
//    }
    
//    return -1;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currPlaybackTime {
//    if ( [self isPreparedToPlay] ) {
        [chromecastDeviceController setPlaybackPercent: currPlaybackTime];
    
//    }
}

- (BOOL)isPreparedToPlay {
    return chromecastDeviceController && [chromecastDeviceController isConnected];
}

- (void)bindPlayerEvents {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(triggerMediaNowPlaying:)
                                                 name: ChromcastDeviceControllerMediaNowPlayingNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(volumeChanged:)
                                                 name: @"AVSystemController_SystemVolumeDidChangeNotification"
                                               object: nil];
}

- (void)triggerMediaNowPlaying:(NSNotification*)notification {
    NSLog(@"triggerMediaNowPlaying Enter");
    
    [self triggerKPlayerEvents: @"play" withValue: nil];
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
    
    NSLog(@"triggerMediaNowPlaying Exit");
}

- (void)triggerKPlayerEvents: (NSString *)notName withValue: (NSDictionary *)notValueDict {
    NSLog(@"triggerKPlayerEvents Enter");
    
    [[NSNotificationCenter defaultCenter] postNotificationName: notName object: nil userInfo: notValueDict];
    
    NSLog(@"triggerKPlayerEvents Exit");
}

- (void)sendCurrentTime:(NSTimer *)timer {
    if ( ( [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive )
        && ( [self playbackState] == GCKMediaPlayerStatePlaying ) ) {
        [self triggerKPlayerEvents: @"timeupdate"
                         withValue: @{@"timeupdate": [NSString stringWithFormat:@"%f", [self getCurrentPlaybackTime]]}];
    }
}

- (void)updatePlaybackProgressFromTimer:(NSTimer *)timer {
    if ( ( [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive )
        && ( [self playbackState] == GCKMediaPlayerStatePlaying ) ) {
        CGFloat progress = [self playableDuration] / [self duration];
        [self triggerKPlayerEvents: @"progress"
                         withValue: @{@"progress": [NSString stringWithFormat:@"%f", progress]}];
    }
}

- (void) volumeChanged:(NSNotification *)notification {
    NSLog(@"onMovieDurationAvailable Enter");
    
    float volume = [[[notification userInfo]
                     objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"]
                    floatValue];
    
    [chromecastDeviceController changeVolume: volume];
    
    NSLog(@"onMovieDurationAvailable Exit");
}

@end
