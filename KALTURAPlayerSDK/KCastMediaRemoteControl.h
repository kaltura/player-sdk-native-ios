//
//  KCastMediaRemoteControl.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 10/07/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KChromeCastWrapper.h"

@protocol KCastMediaRemoteControlDelegate <NSObject>

- (void)updateProgress:(NSTimeInterval)currentTime;
- (void)readyToPlay:(NSTimeInterval)streamDuration;
- (void)castPlayerState:(NSString *)state;

@end

@protocol KCastMediaRemoteControl <NSObject>
@property(nonatomic, strong, readonly) id mediaStatus;
@property (nonatomic) NSTimeInterval currentTime;
- (NSInteger)seekToTimeInterval:(NSTimeInterval)position;
- (void)play;
- (void)pause;
- (NSInteger)stop;
- (NSInteger)setStreamVolume:(float)volume;
- (NSInteger)setStreamMuted:(BOOL)muted;
- (void)addObserver:(id<KCastMediaRemoteControlDelegate>)observer;
- (void)removeObserver:(id<KCastMediaRemoteControlDelegate>)observer;
@end
