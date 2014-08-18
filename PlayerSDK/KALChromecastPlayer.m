//
//  KALChromecastPlayer.m
//  PlayerSDK
//
//  Created by Eliza Sapir on 5/12/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KALChromecastPlayer.h"

@implementation KALChromecastPlayer
@synthesize chromecastDeviceController;

- (CGFloat) getCurrentTime {
    if ( self.isPreparedToPlay ) {
        [chromecastDeviceController updateStatsFromDevice];
        return chromecastDeviceController.streamPosition;
    }
    
    return -1;
}

-(void)showChromecastDeviceList {
    NSLog(@"showChromecastDeviceList Enter");
    
    if ( chromecastDeviceController ) {
        [chromecastDeviceController chooseDevice: self];
    }
    
    NSLog(@"showChromecastDeviceList Exit");
}

- (void) didLoad {
    
    if (self) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(deviceConnected:)
         name:ChromcastDeviceControllerDeviceConnectedNotification
         object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(volumeChanged:)
                                                     name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                                   object:nil];
        
        [ [NSNotificationCenter defaultCenter] addObserver: self
                                                  selector: @selector(showChromecastButton:)
                                                      name: @"showChromecastButtonNotification"
                                                    object: nil ];
        
        [ [NSNotificationCenter defaultCenter] addObserver: self
                                                  selector: @selector(hideChromecastButton:)
                                                      name: @"hideChromecastButtonNotification"
                                                    object: nil ];
        [ [NSNotificationCenter defaultCenter] addObserver: self
                                                  selector: @selector(chromecastDeviceDisConnected:)
                                                      name: ChromcastDeviceControllerDeviceDisconnectedNotification
                                                    object: nil ];
        
        [ [NSNotificationCenter defaultCenter] addObserver: self
                                                  selector: @selector(chromecastDevicePlaying:)
                                                      name: ChromcastDeviceControllerMediaNowPlayingNotification
                                                    object: nil ];
    }
    
    // Chromecast
    // Initialize the chromecast device controller.
    chromecastDeviceController = [ [ChromecastDeviceController alloc] init ];
    [chromecastDeviceController performScan: YES];
    showChromecastButton = NO;
}

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

-(void)notifyLayoutReady {

    if ( chromecastDeviceController ) {
        if ([self respondsToSelector:@selector(setKDPAttribute:propertyName:value:)]) {
            [self.kDPApi setKDPAttribute: @"chromecast" propertyName: @"visible" value: showChromecastButton ? @"true" : @"false"];
        }
    }
    
}

-(void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
    if ([self isPreparedToPlay]) {
        [ chromecastDeviceController setPlaybackPercent:  currentTime];
    }
}

- (void)deviceConnected:(NSNotification*)notification {
    if ([[notification name] isEqualToString:ChromcastDeviceControllerDeviceConnectedNotification]) {
        NSLog(@"Device has been Connected!");
        
        //Push Chromecast Segue
        if ( [self isPreparedToPlay] ) {
            //_lastKnownPlaybackTime = [self currentPlaybackTime];
            [self stop];
        }
    }
    
    // TODO: change to playerSource
    [chromecastDeviceController loadMedia: self.contentURL thumbnailURL: nil title:@"" subtitle:@"" mimeType:@"" startTime: self.currentPlaybackTime autoPlay: YES];
    [self.kDPApi triggerEventsJavaScript:@"chromecastDeviceConnected" WithValue:nil];
}

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

- (void)showChromecastButton: (NSNotification *)note {
    showChromecastButton = @"true";
    [self.kDPApi setKDPAttribute: @"chromecast" propertyName: @"visible" value: showChromecastButton ? @"true" : @"false"];
}

- (void)hideChromecastButton: (NSNotification *)note {
    showChromecastButton = @"false";
    [self.kDPApi setKDPAttribute: @"chromecast" propertyName: @"visible" value: showChromecastButton ? @"true" : @"false"];
}

- (void)chromecastDeviceDisConnected: (NSNotification *)note {
    [self.kDPApi triggerEventsJavaScript:@"chromecastDeviceDisConnected" WithValue:nil];
    self.currentPlaybackTime = chromecastDeviceController.streamPosition;
}

- (void)chromecastDevicePlaying: (NSNotification *)note {
    [self.kDPApi triggerEventsJavaScript:@"play" WithValue:nil];
}

@end
