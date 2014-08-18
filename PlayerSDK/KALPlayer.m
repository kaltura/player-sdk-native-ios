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
    if (delegate && [delegate respondsToSelector:@selector(kPlayerDidPlay)]) {
        [delegate kPlayerDidPlay];
    }
    
    [super play];
}

//KALPlayer *kp = [KALPlayer new];
//[kp setDelegate: self];



@end
