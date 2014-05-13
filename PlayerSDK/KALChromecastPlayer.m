//
//  KALChromecastPlayer.m
//  PlayerSDK
//
//  Created by Eliza Sapir on 5/12/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KALChromecastPlayer.h"

@implementation KALChromecastPlayer

- (void) didLoad {
    
    if (self) {
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(deviceConnected:)
         name:ChromcastDeviceControllerDeviceConnectedNotification
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

- (void)deviceConnected:(NSNotification*)notification {
    if ([[notification name] isEqualToString:ChromcastDeviceControllerDeviceConnectedNotification]) {
        NSLog(@"Device has been Connected!");
        
        //Push Chromecast Segue
        if ( chromecastDeviceController.isConnected ) {
            //_lastKnownPlaybackTime = [self currentPlaybackTime];
            [self stop];
        }
    }
    
    // TODO: change to playerSource
    [chromecastDeviceController loadMedia: self.contentURL thumbnailURL: nil title:@"" subtitle:@"" mimeType:@"" startTime: self.currentPlaybackTime autoPlay: YES];
    [self.delegate triggerEventsJavaScript:@"chromecastDeviceConnected" WithValue:nil];
}

#pragma mark - Chromecast Methods

-(void)playChromecast {
    NSLog(@"playChromecast Enter");
    
    [chromecastDeviceController pauseCastMedia: NO];
    
    NSLog(@"playChromecast Exit");
}

-(void)pauseChromecast {
    NSLog(@"pauseChromecast Enter");
    
    [chromecastDeviceController pauseCastMedia: YES];
    
    NSLog(@"pauseChromecast Exit");
}

-(void)stopChromecast {
    NSLog(@"stopChromecast Enter");
    
    [chromecastDeviceController stopCastMedia];
    
    NSLog(@"stopChromecast Exit");
}

@end
