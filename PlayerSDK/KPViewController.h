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

+ (void)setURLScheme:(NSURL *)url;
+ (NSURL *)URLScheme;

@property (nonatomic, strong) IBOutlet KPControlsWebView* webView;
@property (nonatomic, retain) NativeComponentPlugin *nativComponentDelegate;
@property (nonatomic, strong) id<KalturaPlayer> player;
@property (readwrite, nonatomic, copy) JSCallbackReadyHandler jsCallbackReadyHandler;
@property (nonatomic, weak) id<KPViewControllerDatasource> datasource;


- (instancetype) initWithFrame:(CGRect)frame forView:(UIView *)parentView;
- (void)stopAndRemovePlayer;
- (void)checkOrientationStatus;
- (void)resizePlayerView: (CGFloat )top right: (CGFloat )right width: (CGFloat )width height: (CGFloat )height;
- (void)openFullscreen;
- (void)closeFullscreen;
- (void)checkDeviceStatus;
- (void)setNativeFullscreen;
- (void)setWebViewURL: (NSString *)iframeUrl;
+ (id)sharedChromecastDeviceController;
- (void)load;

// Kaltura Player External API
- (void)registerJSCallbackReady: (JSCallbackReadyHandler)handler;
- (void)addKPlayerEventListener: (NSString *)name forListener: (KPEventListener *)listener;
- (void)removeKPlayerEventListenerWithEventName: (NSString *)name forListenerName: (NSString *)listenerName;
- (void)asyncEvaluate: (NSString *)expression forListener: (KPEventListener *)listener;
- (void)sendNotification: (NSString*)notificationName andNotificationBody: (NSString *)notificationBody;
- (void)setKDPAttribute: (NSString*)pluginName propertyName: (NSString*)propertyName value: (NSString*)value;
- (void)triggerEventsJavaScript: (NSString *)eventName WithValue: (NSString *) eventValue;


@property (nonatomic, retain) NSMutableDictionary *players;

@property (nonatomic, copy, readonly) void (^addEventListener)(NSString *event);

@end

