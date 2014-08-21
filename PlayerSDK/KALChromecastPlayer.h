//
//  KALChromecastPlayer.h
//  PlayerSDK
//
//  Created by Eliza Sapir on 5/12/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KALPlayer.h"
#import "ChromecastDeviceController.h"
//#import "KALChromecastPlayer.h"

@interface KALChromecastPlayer : NSObject  <KalturaPlayer> {
    BOOL showChromecastButton;
}

@property (nonatomic, assign) id<KDPApi> kDPApi;

- (void)pause;
- (void)play;
- (void)stop;
- (double)currentPlaybackTime;
- (int)playbackState;
- (BOOL)isPreparedToPlay;
- (void)setContentURL:(NSURL *)url;
- (double)playableDuration;
- (double)duration;

@end
