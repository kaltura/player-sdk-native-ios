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
@class DRMHandler;

static NSString *ChromecastClassName = @"KPChromecast";
static NSString *PlayerClassName = @"KPlayer";

static NSString *ChromeCastPlayerClassName = @"";
static NSString *WideVinePlayerClass = @"WVPlayer";


@protocol KPlayerEventsDelegate;

@protocol KPlayer <NSObject>

@property (nonatomic, weak) id<KPlayerEventsDelegate> delegate;
@property (nonatomic, copy) NSURL *playerSource;
@property (nonatomic) NSTimeInterval currentPlaybackTime;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic, readonly) BOOL isKPlayer;


- (instancetype)initWithParentView:(UIView *)parentView;
- (void)play;
- (void)pause;
- (void)removePlayer;

@optional
@property (nonatomic, copy) NSString *DRMKey;
@end

@protocol KPlayerEventsDelegate <NSObject>

- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event value:(NSString *)value;

@optional
- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event JSON:(NSString *)jsonString;

@end


@interface KPlayerController : NSObject

- (instancetype)initWithPlayerClassName:(NSString *)className;
- (void)addPlayerToController:(UIViewController *)parentViewController;
- (void)switchPlayer:(NSString *)playerClassName key:(NSString *)key;
- (void)contentCompleted;

@property (nonatomic, strong) id<KPlayer> player;
@property (nonatomic, copy) NSString *playerClassName;
@property (nonatomic, copy) NSString *src;
@property (nonatomic, copy) NSString *adTagURL;
@property (nonatomic) NSTimeInterval currentPlayBackTime;
@property (nonatomic) CGFloat adPlayerHeight;
@property (nonatomic, copy) NSString *locale;
@end
