//
//  KPCastProvider.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 18/09/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "CastProviderInternalDelegate.h"

@protocol KPCastProviderDelegate <NSObject>

- (void)updateProgress:(NSTimeInterval)currentTime;
- (void)readyToPlay:(NSTimeInterval)streamDuration;
- (void)castPlayerState:(NSString *)state;
- (void)startCasting;

@end

@protocol KPCastProvider <NSObject>
@property(nonatomic, strong, readonly) id mediaStatus;
@property (nonatomic) NSTimeInterval currentTime;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) BOOL wasReadyToplay;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, weak) id<KPCastProviderDelegate> delegate;

- (NSInteger)seekToTimeInterval:(NSTimeInterval)position;
- (void)play;
- (void)pause;
- (NSInteger)stop;
- (NSInteger)setStreamVolume:(float)volume;
- (NSInteger)setStreamMuted:(BOOL)muted;
- (void)addObserver:(id<KPCastProviderDelegate>)observer;
- (void)removeObserver:(id<KPCastProviderDelegate>)observer;
- (BOOL)sendTextMessage:(NSString *)message;
- (void)setVideoUrl:(NSString *)videoUrl startPosition:(NSTimeInterval)startPosition autoPlay:(BOOL)isAutoPlay;
@end
