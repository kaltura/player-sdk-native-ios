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
NSString *const DoSeekKey = @"doSeek";

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

///@todo setCurrentPlaybackRate
- (void)setCurrentPlaybackRate:(float)currentPlaybackRate {

}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currPlaybackTime {
    if ([_delegate respondsToSelector:@selector(sendKPNotification:withParams:)]) {
        [_delegate sendKPNotification:DoSeekKey withParams:[@(currPlaybackTime) stringValue]];
    }
}

- (BOOL)isPreparedToPlay {
    return nil;
}

@end
