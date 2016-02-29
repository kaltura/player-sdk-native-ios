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
#import "KPIMAPlayerViewController.h"
#import "KPViewControllerProtocols.h"

static NSString *ChromecastClassName = @"KPChromecast";
static NSString *PlayerClassName = @"KPlayer";

static NSString *ChromeCastPlayerClassName = @"KCCPlayer";
static NSString *WideVinePlayerClass = @"WVPlayer";

static NSString *PlayKey = @"play";
static NSString *PauseKey = @"pause";
static NSString *StopKey = @"stop";
static NSString *DurationChangedKey = @"durationchange";
static NSString *LoadedMetaDataKey = @"loadedmetadata";
static NSString *TimeUpdateKey = @"timeupdate";
static NSString *ProgressKey = @"progress";
static NSString *EndedKey = @"ended";
static NSString *SeekedKey = @"seeked";
static NSString *CanPlayKey = @"canplay";
static NSString *ErrorKey = @"error";
static NSString *BufferingChangeKey = @"bufferchange";
static NSString *PostrollEndedKey = @"postEnded";

@protocol KPlayerFactoryDelegate <KPlayerDelegate>
- (void)allAdsCompleted;
@end

@interface KPlayerFactory : NSObject 

- (instancetype)initWithPlayerClassName:(NSString *)className;
- (void)addPlayerToController:(UIViewController *)parentViewController;
- (void)switchPlayer:(NSString *)playerClassName key:(NSString *)key;
- (id<KPlayer>)createPlayerFromClassName:(NSString *)className;
- (void)changePlayer:(id<KPlayer>)player;
- (void)changeSubtitleLanguage:(NSString *)isoCode;
- (void)removePlayer;
- (void)enableTracks:(BOOL)isEnablingTracks;
- (void)prepareForChangeConfiguration;

@property (nonatomic, strong) id<KPlayer> player;
@property (nonatomic, weak) id<KPlayerFactoryDelegate> delegate;
@property (nonatomic, copy) NSString *playerClassName;
@property (nonatomic, copy) NSString *src;
@property (nonatomic, copy) NSString *adTagURL;
@property (nonatomic) NSTimeInterval currentPlayBackTime;
@property (nonatomic) CGFloat adPlayerHeight;
@property (nonatomic, copy) NSString *locale;
@property (nonatomic, copy) NSString *licenseUri;
@property (nonatomic, strong) KPIMAPlayerViewController *adController;
@property (nonatomic, strong) id kIMAWebOpenerDelegate;
@end
