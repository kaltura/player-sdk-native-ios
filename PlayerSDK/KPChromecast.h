//
//  KALChromecastPlayer.h
//  PlayerSDK
//
//  Created by Eliza Sapir on 5/12/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KalturaPlayer.h"
#import "ChromecastDeviceController.h"
#import "KPViewController.h"
#import "KPViewControllerProtocols.h"


@interface KPChromecast : NSObject <KalturaPlayer>

- (void)pause;
- (void)play;
- (void)stop;
- (int)playbackState;
- (BOOL)isPreparedToPlay;
- (void)setContentURL:(NSURL *)url;
- (double)playableDuration;
- (double)duration;
- (void)bindPlayerEvents;
- (void)sendCurrentTime:(NSTimer *)timer;
- (void)updatePlaybackProgressFromTimer:(NSTimer *)timer;
- (NSTimeInterval)currentPlaybackTime;
- (void)setCurrentPlaybackTime:(double)cs;
- (void)triggerMediaNowPlaying;
- (void)triggerMediaNowPaused;

@end
