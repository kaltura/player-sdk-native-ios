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
    NSURL *contentURL;
}

@synthesize delegate;
@synthesize currentPlaybackTime;
@synthesize view;
@synthesize playbackState;
@synthesize loadState;
@synthesize isPreparedToPlay;

- (void) copyParamsFromPlayer:(id<KalturaPlayer>) player {
    if (self) {
        chromecastDeviceController = (ChromecastDeviceController *)[KalPlayerViewController sharedChromecastDeviceController];
        
        if ( [self isPreparedToPlay] ) {
            self.currentPlaybackTime = player.currentPlaybackTime;
        }
        
        [self setContentURL: [player contentURL]];
    }
}

- (int)playbackState {
    return chromecastDeviceController.playerState;
}

- (NSURL *)contentURL {
    return contentURL;
}

- (void)setContentURL:(NSURL *)url {
    contentURL = url;
    [chromecastDeviceController loadMedia: url thumbnailURL: nil title:@"" subtitle:@"" mimeType:@"" startTime: self.currentPlaybackTime autoPlay: YES];
}

- (double)playableDuration {
    return chromecastDeviceController.streamDuration;
}

- (double)duration {
    return chromecastDeviceController.streamDuration;
}

- (double)currentPlaybackTime {
    return [self getCurrentTime];
}

- (CGFloat) getCurrentTime {
    if ( self.isPreparedToPlay ) {
        [chromecastDeviceController updateStatsFromDevice];
        return chromecastDeviceController.streamPosition;
    }
    
    return -1;
}

//-(void)showChromecastDeviceList {
//    NSLog(@"showChromecastDeviceList Enter");
//    
//    if ( chromecastDeviceController ) {
//        [chromecastDeviceController chooseDevice: self];
//    }
//    
//    NSLog(@"showChromecastDeviceList Exit");
//}

- (void) volumeChanged:(NSNotification *)notification {
    NSLog(@"onMovieDurationAvailable Enter");
    
    float volume = [[[notification userInfo]
                     objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"]
                    floatValue];
    
    [chromecastDeviceController changeVolume: volume];
    
    NSLog(@"onMovieDurationAvailable Exit");
}

- (BOOL) isPreparedToPlay {
    return chromecastDeviceController && chromecastDeviceController.isConnected;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
    if ([self isPreparedToPlay]) {
        [ chromecastDeviceController setPlaybackPercent:  currentTime];
    }
}

//- (void)deviceConnected:(NSNotification*)notification {
//    if ([[notification name] isEqualToString:ChromcastDeviceControllerDeviceConnectedNotification]) {
//        NSLog(@"Device has been Connected!");
//        
//        //Push Chromecast Segue
//        if ( [self isPreparedToPlay] ) {
//            //_lastKnownPlaybackTime = [self currentPlaybackTime];
//            [self stop];
//        }
//    }
//    
//    // TODO: change to playerSource
//    [chromecastDeviceController loadMedia: self.contentURL thumbnailURL: nil title:@"" subtitle:@"" mimeType:@"" startTime: self.currentPlaybackTime autoPlay: YES];
//    [self.kDPApi triggerEventsJavaScript:@"chromecastDeviceConnected" WithValue:nil];
//}

#pragma mark - Chromecast Methods

-(void)play {
    NSLog(@"playChromecast Enter");
    
    [chromecastDeviceController pauseCastMedia: NO];
    
    NSLog(@"playChromecast Exit");
}

-(void)pause {
    NSLog(@"pauseChromecast Enter");
    
    [chromecastDeviceController pauseCastMedia: YES];
    
    NSLog(@"pauseChromecast Exit");
}

-(void)stop {
    NSLog(@"stopChromecast Enter");
    
    [chromecastDeviceController stopCastMedia];
    
    NSLog(@"stopChromecast Exit");
}

@end
