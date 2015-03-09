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
#import "KPLog.h"
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

+ (void)setLogLevel:(KPLogLevel)logLevel;
- (instancetype) initWithFrame:(CGRect)frame forView:(UIView *)parentView;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)stopAndRemovePlayer;
- (void)checkOrientationStatus;
- (void)resizePlayerView:(CGRect)newFrame;
- (void)openFullscreen;
- (void)closeFullscreen;
- (void)checkDeviceStatus;
- (void)setNativeFullscreen;
- (void)setWebViewURL: (NSString *)iframeUrl;
+ (id)sharedChromecastDeviceController;
- (void)changeMedia:(NSString *)mediaID;
- (void)load;

// Kaltura Player External API


/*!
 * @function registerReadyEvent
 *
 * @abstract
 * Registers to the players ready event
 *
 * @discussion
 * The registerReadyEvent function will notify that the player has been loaded
 * and it's possible to interact with it.
 *
 * Calls to registerReadyEvent will invoke the handler when the player is ready
 *
 *
 * @param handler
 * Callback for the ready event.
 *
 */
- (void)registerReadyEvent:(void(^)())handler;


/*!
 * @function addEventListener:eventID:handler:
 *
 * @abstract
 * Registers to one of the players events
 *
 * @param NSString name of One of the players events
 * @param NSString event id, will enable to remove the current event by id
 * @param handler Callback for the ready event.
 */
- (void)addEventListener:(NSString *)event
                 eventID:(NSString *)eventID
                 handler:(void(^)(NSString *eventName))handler;


/*!
 * @function removeEventListener:eventID
 *
 * @abstract
 * Removes One of the players events by id
 *
 * @param NSString event, name of One of the players events.
 * @param NSString eventID, event id for removal.
 * @param handler Callback for the ready event.
 */
- (void)removeEventListener:(NSString *)event
                    eventID:(NSString *)eventID;



/*!
 * @function asyncEvaluate:expressionID:handler
 *
 * @abstract
 * Evaluates values from the player
 *
 * @param NSString expression, @"{mediaProxy.entry.thumbnailUrl}:
 * @param NSString expressionID, expression id use for several expressions.
 * @param handler Callback with the value of the expression.
 */
- (void)asyncEvaluate:(NSString *)expression
         expressionID:(NSString *)expressionID
              handler:(void(^)(NSString *value))handler;



/*!
 * @function sendNotification:expressionID:forName
 *
 * @abstract
 * Notifies the player on specific events
 *
 * @param NSString notification, notification body
 * @param NSString notificationName, notification name s specific notification.
 */
- (void)sendNotification:(NSString *)notification
                 forName:(NSString *)notificationName;



/*!
 * @function setKDPAttribute:propertyName:value
 *
 * @abstract
 * Controls elements in the player layer
 *
 * @param NSString pluginName, represents specific element
 * @param NSString propertyName, property of the plugin
 * @param NSString value, sets the property
 */
- (void)setKDPAttribute:(NSString *)pluginName
           propertyName:(NSString *)propertyName
                  value:(NSString *)value;



/*!
 * @function triggerEvent:withValue
 *
 * @abstract
 * Triggers JavaScript methods on the player
 *
 * @param NSString event, methods name
 * @param NSString value, params for the method
 */
- (void)triggerEvent:(NSString *)event
           withValue:(NSString *)value;



/// Wrraps registerReadyEvent: method by block syntax.
@property (nonatomic, copy) void (^registerReadyEvent)(void(^readyCallback)());

/// Wrraps addEventListener:eventID:handler: method by block syntax.
@property (nonatomic, copy, readonly) void (^addEventListener)(NSString *event, NSString *eventID, void(^)(NSString *eventName));

/// Wrraps removeEventListener:eventID: method by block syntax.
@property (nonatomic, copy, readonly) void (^removeEventListener)(NSString *event, NSString *eventID);

/// Wrraps asyncEvaluate:expressionID:handler: method by block syntax.
@property (nonatomic, copy, readonly) void (^asyncEvaluate)(NSString *expression, NSString *expressionID, void(^)(NSString *value));

/// Wrraps sendNotification:expressionID:forName: method by block syntax.
@property (nonatomic, copy, readonly) void (^sendNotification)(NSString *notification, NSString *notificationName);

/// Wrraps setKDPAttribute:propertyName:value: method by block syntax.
@property (nonatomic, copy, readonly) void (^setKDPAttribute)(NSString *pluginName, NSString *propertyName, NSString *value);

/// Wrraps triggerEvent:withValue: method by block syntax.
@property (nonatomic, copy, readonly) void (^triggerEvent)(NSString *event, NSString *value);


@end

