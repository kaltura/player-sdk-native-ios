//
//  KALPlayer.m
//  KalPlayerSDK
//
//  Created by Eliza Sapir on 8/13/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KALPlayer.h"

@implementation KALPlayer
@synthesize delegate;
@synthesize currentPlaybackTime;
@synthesize view;
@synthesize controlStyle;
@synthesize playbackState;
@synthesize loadState;
@synthesize isPreparedToPlay;
@synthesize contentURL;

- (void)play {
    NSLog(@"Now Playing...");
    [super play];
}


@end
