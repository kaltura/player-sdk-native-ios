//
//  KPMoviePlayerController.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 7/2/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPController.h"

@implementation KPController
@synthesize currentPlaybackRate;
@synthesize currentPlaybackTime;

NSString *const DoPlayKey = @"doPlay";
NSString *const DoPauseKey = @"doPause";
NSString *const DoStopKey = @"doStop";

- (void)prepareToPlay {
    
}

- (void)play {
    if ([_delegate respondsToSelector:@selector(sendKPNotification:withParams:)]) {
        [_delegate sendKPNotification:DoPlayKey withParams:nil];
    }
}

- (void)pause {
    if ([_delegate respondsToSelector:@selector(sendKPNotification:withParams:)]) {
        [_delegate sendKPNotification:DoPauseKey withParams:nil];
    }
}

- (void)stop {
    if ([_delegate respondsToSelector:@selector(sendKPNotification:withParams:)]) {
        [_delegate sendKPNotification:DoStopKey withParams:nil];
    }
}

- (void)setCurrentPlaybackRate:(float)currentPlaybackRate {
    
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
    
}

- (BOOL)isPreparedToPlay {
    return nil;
}

@end
