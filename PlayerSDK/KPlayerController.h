//
//  KPlayerManager.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/16/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

static NSString *ChromecastClassName = @"KPChromecast";
static NSString *PlayerClassName = @"KPlayer";

@protocol KPlayerEventsDelegate <NSObject>

- (void)updateTime:(NSTimeInterval)time progress:(NSTimeInterval)progress;
- (void)seekedToTime:(NSTimeInterval)seekedTime;
- (void)eventName:(NSString *)event value:(NSString *)value;

@end

@protocol KPlayer <NSObject>

@property (nonatomic, weak) id<KPlayerEventsDelegate> delegate;
@property (nonatomic, copy) NSURL *playerSource;
@property (nonatomic) NSTimeInterval currentPlaybackTime;
@property (nonatomic) NSTimeInterval duration;

- (instancetype)initWithParentView:(UIView *)parentView;
- (void)play;
- (void)pause;


@end




@interface KPlayerController : NSObject

- (instancetype)initWithPlayerClassName:(NSString *)className;
- (void)addPlayerToView:(UIView *)parentView;

@property (nonatomic, strong) id<KPlayer> player;
@property (nonatomic, copy) NSString *playerClassName;
@property (nonatomic, copy) NSString *src;
@property (nonatomic) NSTimeInterval currentPlayBackTime;
@property (nonatomic, copy) NSString *wideVineKey;

@end
