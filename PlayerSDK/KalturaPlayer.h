//
//  KALPlayer.h
//  KalPlayerSDK
//
//  Created by Eliza Sapir on 8/13/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "KPViewController.h"

//#import <Pods/GoogleAds-IMA-iOS-SDK/GoogleIMASDK3/IMAAdsLoader.h>

//#import <IMAAdsLoader.h>
//#import <IMAAdsManager.h>

@interface KalturaPlayer : MPMoviePlayerController <KalturaPlayer>

- (void)pause;
- (void)play;
- (void)stop;
- (id)view;
- (int)controlStyle;
- (int)playbackState;
- (int)loadState;
- (void)prepareToPlay;
- (BOOL)isPreparedToPlay;
- (void)setContentURL:(NSURL *)url;
- (double)playableDuration;
- (double)duration;
- (void)bindPlayerEvents;
- (void)sendCurrentTime:(NSTimer *)timer;
- (void)updatePlaybackProgressFromTimer:(NSTimer *)timer;
- (NSTimeInterval)currentPlaybackTime;
- (void)setCurrentPlaybackTime:(double)cs;
- (void)initWV: (NSString *)src andKey: (NSString *)key;
- (void)setWideVideConfigurations;

@end
