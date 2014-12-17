//
//  KalPlayerViewController.h
//  HelloWorld
//
//  Created by Eliza Sapir on 9/11/13.
//
//

/* This class is responsible for player sdk
 in this class we have a player which contains a webview as subview, the webview reflects html5 NativeComponent */

// Copyright (c) 2013 Kaltura, Inc. All rights reserved.
// License: http://corp.kaltura.com/terms-of-use
//

static NSString *KPlayerEventCanplay = @"canplay";
static NSString *KPlayerEventDurationChange = @"durationchange";
static NSString *KPlayerEventLoadedMetadata = @"loadedmetadata";
static NSString *KPlayerEventPlay = @"play";
static NSString *KPlayerEventPause = @"pause";
static NSString *KPlayerEventEnded = @"ended";
static NSString *KPlayerEventSeeking = @"seeking";
static NSString *KPlayerEventSeeked = @"seeked";
static NSString *KPlayerEventTimeupdate = @"timeupdate";
static NSString *KPlayerEventProgress = @"progress";
static NSString *KPlayerEventToggleFullScreen = @"toggleFullscreen";


@protocol KalturaPlayer;

#import <MediaPlayer/MediaPlayer.h>
#import "KPControlsWebView.h"

#import "KalturaPlayer.h"
#import "KPChromecast.h"
#import "ChromecastDeviceController.h"
#import "KPViewControllerProtocols.h"



@class KPViewController;
@class NativeComponentPlugin;
@class KPEventListener;

@protocol KPViewControllerDelegate;
@protocol KalturaPlayer;
@protocol KPViewControllerDatasource;



@interface KPViewController : UIViewController <PlayerControlsWebViewDelegate, ChromecastControllerDelegate> {
    id<KalturaPlayer> player;
    NativeComponentPlugin *nativComponentDelegate;
    id<KPViewControllerDelegate> kalPlayerViewControllerDelegate;
}


@property (nonatomic, strong) IBOutlet KPControlsWebView* webView;
@property (nonatomic, retain) NativeComponentPlugin *nativComponentDelegate;
@property (nonatomic, strong) id<KalturaPlayer> player;
@property (nonatomic, weak) id<KPViewControllerDatasource> datasource;
@property (nonatomic, retain) NSMutableDictionary *players;

@property (nonatomic, assign) CGRect playerFrame;

- (instancetype) initWithFrame:(CGRect)frame forView:(UIView *)parentView;
- (void)stopAndRemovePlayer;
- (void)checkOrientationStatus;
- (void)resizePlayerView:(CGRect)newFrame;
- (void)openFullscreen;
- (void)closeFullscreen;
- (void)checkDeviceStatus;
- (void)setNativeFullscreen;
- (void)setWebViewURL: (NSString *)iframeUrl;
+ (id)sharedChromecastDeviceController;
- (void)load;

// Kaltura Player External API

- (void)registerReadyEvent:(void(^)())handler;

- (void)addEventListener:(NSString *)event
                 eventID:(NSString *)eventID
                 handler:(void(^)())handler;

- (void)removeEventListener:(NSString *)event
                    eventID:(NSString *)eventID;

- (void)asyncEvaluate:(NSString *)expression
         expressionID:(NSString *)expressionID
              handler:(void(^)(NSString *value))handler;

- (void)sendNotification:(NSString *)notification
                 forName:(NSString *)notificationName;

- (void)setKDPAttribute:(NSString *)pluginName
           propertyName:(NSString *)propertyName
                  value:(NSString *)value;

- (void)triggerEvent:(NSString *)event
           withValue:(NSString *)value;




@property (nonatomic, copy) void (^registerReadyEvent)(void(^readyCallback)());

@property (nonatomic, copy, readonly) void (^addEventListener)(NSString *event, NSString *eventID, void(^)());

@property (nonatomic, copy, readonly) void (^removeEventListener)(NSString *event, NSString *eventID);

@property (nonatomic, copy, readonly) void (^asyncEvaluate)(NSString *expression, NSString *expressionID, void(^)(NSString *value));

@property (nonatomic, copy, readonly) void (^sendNotification)(NSString *notification, NSString *notificationName);

@property (nonatomic, copy, readonly) void (^setKDPAttribute)(NSString *pluginName, NSString *propertyName, NSString *value);

@property (nonatomic, copy, readonly) void (^triggerEvent)(NSString *event, NSString *value);


@end

