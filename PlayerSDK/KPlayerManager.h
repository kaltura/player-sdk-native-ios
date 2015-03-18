//
//  KPlayerManager.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/16/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol KPlayerEventsDelegate <NSObject>

- (void)updateTime:(NSTimeInterval)time progress:(NSTimeInterval)progress;
- (void)durationChanged:(NSTimeInterval)duration;
- (void)seekedToTime:(NSTimeInterval)seekedTime;

@end

@protocol KPlayer <NSObject>
@property (nonatomic, strong) UIView *view;
@property (nonatomic, weak) id<KPlayerEventsDelegate> delegate;

- (void)play;
- (void)pause;
- (void)seekToTime:(NSTimeInterval)time;

@end

@interface KPlayerManager : NSObject
- (void)addPlayerToView:(UIView *)parentView;
@end
