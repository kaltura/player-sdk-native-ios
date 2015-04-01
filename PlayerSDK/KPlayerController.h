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

static NSString *PlayKey = @"play";
static NSString *PauseKey = @"pause";
static NSString *DurationChangedKey = @"durationchange";
static NSString *LoadedMetaDataKey = @"loadedmetadata";
static NSString *TimeUpdateKey = @"timeupdate";
static NSString *ProgressKey = @"progress";
static NSString *EndedKey = @"ended";
static NSString *SeekedKey = @"seeked";
static NSString *CanPlayKey = @"canplay";
static NSString *PostrollEndedKey = @"postEnded";


@protocol KPlayerDelegate;

@protocol KPlayer <NSObject>

@property (nonatomic, weak) id<KPlayerDelegate> delegate;
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

@protocol KPlayerDelegate <NSObject>

- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event value:(NSString *)value;
- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event JSON:(NSString *)jsonString;
- (void)contentCompleted:(id<KPlayer>)currentPlayer;

@end

@protocol KPlayerControllerDelegate <KPlayerDelegate>

- (void)allAdsCompleted;

@end

@interface KPlayerController : NSObject

- (instancetype)initWithPlayerClassName:(NSString *)className;
- (void)addPlayerToController:(UIViewController *)parentViewController;
- (void)switchPlayer:(NSString *)playerClassName key:(NSString *)key;
- (void)removePlayer;

@property (nonatomic, strong) id<KPlayer> player;
@property (nonatomic, weak) id<KPlayerControllerDelegate> delegate;
@property (nonatomic, copy) NSString *playerClassName;
@property (nonatomic, copy) NSString *src;
@property (nonatomic, copy) NSString *adTagURL;
@property (nonatomic) NSTimeInterval currentPlayBackTime;
@property (nonatomic) CGFloat adPlayerHeight;
@property (nonatomic, copy) NSString *locale;
@end
