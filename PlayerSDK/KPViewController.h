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

#import "KPLog.h"
#import "KPViewControllerProtocols.h"
#import "KPPlayerConfig.h"
#import "KPController.h"

@class KPViewController;
@protocol KPViewControllerDelegate <NSObject>
@optional
- (void)updateCurrentPlaybackTime:(double)currentPlaybackTime;
- (void)kPlayer:(KPViewController *)player playerLoadStateDidChange:(KPMediaLoadState)state;
- (void)kPlayer:(KPViewController *)player playerPlaybackStateDidChange:(KPMediaPlaybackState)state;
- (void)kPlayer:(KPViewController *)player playerFullScreenToggled:(BOOL)isFullScreen;
@end

#import "ChromecastDeviceController.h"


@interface KPViewController : UIViewController

+ (void)setLogLevel:(KPLogLevel)logLevel;

/*!
 *  @function initWithURL:
 *  
 *  @abstract
 *  Initialize Player instance
 *
 *  @param NSURL url of player content
 */
- (instancetype)initWithURL:(NSURL *)url;
 
/*!
 *  @function initWithConfiguration:
 *
 *  @abstract
 *  Initialize Player instance
 *
 *  @param KPPlayerConfig configuration parameters of the player content
 */
- (instancetype)initWithConfiguration:(KPPlayerConfig *)configuration;

/*!
 *  @function loadPlayerIntoViewController:
 *
 *  @abstract
 *  Loads the player controller into the parent controller
 *
 *  @param UIViewController parentViewController the controller which will call the player
 */
- (void)loadPlayerIntoViewController:(UIViewController *)parentViewController;

/*!
 *  @function removePlayer
 *
 *  @abstract
 *  Cleaning all the memory of the player
 *
 */
- (void)removePlayer;


/*!
 *  @function changeMedia:
 *
 *  @abstract
 *  Change the entryID without the need of sending new request
 *
 *  @param NSString entryID the entryID of the new video
 */
- (void)changeMedia:(NSString *)entryID;

@property (nonatomic, retain) id<KPViewControllerDelegate> delegate;

@property (nonatomic, strong) KPController *playerController;


/// Enables to change the player configuration
@property (nonatomic, strong) KPPlayerConfig *configuration;


// Kaltura Player External API

/// Change the source and returns the current source
@property (nonatomic, copy) NSURL *playerSource;

///// Perfoms seek to the currentPlaybackTime and returns the currentPlaybackTime
//@property (nonatomic) NSTimeInterval currentPlaybackTime;

///// @return Duration of the current video
//@property (nonatomic, readonly) NSTimeInterval duration;

/// Assigning this handler will disable the default share action and will supply the share params for custom use.
- (void)setShareHandler:(void(^)(NSDictionary *shareParams))shareHandler;


#pragma mark -
#pragma Kaltura Player External API - KDP API
// -----------------------------------------------------------------------------
// KDP API Types

typedef NS_ENUM(NSInteger, KDPAPIState) {
    /*  Player is not ready to work with the JavaScript API. */
    KDPAPIStateUnknown,
    /*  Player is ready to work with the JavaScript API (jsCallbackReady). */
    KDPAPIStateReady
};

/* The current kdp api state of the KDP API. (read-only)
 The kdp api state is affected by programmatic call to jsCallbackReady. */
@property (nonatomic, readonly) KDPAPIState kdpAPIState;

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
- (void)addKPlayerEventListener:(NSString *)event eventID:(NSString *)eventID handler:(void(^)(NSString *eventName, NSString *params))handler;


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
- (void)removeKPlayerEventListener:(NSString *)event eventID:(NSString *)eventID;



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
- (void)asyncEvaluate:(NSString *)expression expressionID:(NSString *)expressionID handler:(void(^)(NSString *value))handler;



/*!
 * @function sendNotification:expressionID:forName
 *
 * @abstract
 * Notifies the player on specific events
 *
 * @param NSString notificationName, notification name
 * @param NSString params, json string for passing parameters to the controls layer (webview).
 */
- (void)sendNotification:(NSString *)notificationName withParams:(NSString *)params;



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
- (void)setKDPAttribute:(NSString *)pluginName propertyName:(NSString *)propertyName value:(NSString *)value;



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



/// Wraps registerReadyEvent: method by block syntax.
@property (nonatomic, copy) void (^registerReadyEvent)(void(^readyCallback)());

/// Wraps addEventListener:eventID:handler: method by block syntax.
@property (nonatomic, copy, readonly) void (^addEventListener)(NSString *event, NSString *eventID, void(^)(NSString *eventName, NSString *params));

/// Wraps removeEventListener:eventID: method by block syntax.
@property (nonatomic, copy, readonly) void (^removeEventListener)(NSString *event, NSString *eventID);

/// Wraps asyncEvaluate:expressionID:handler: method by block syntax.
@property (nonatomic, copy, readonly) void (^asyncEvaluate)(NSString *expression, NSString *expressionID, void(^)(NSString *value));

/// Wraps sendNotification:expressionID:forName: method by block syntax.
@property (nonatomic, copy, readonly) void (^sendNotification)(NSString *notification, NSString *notificationName);

/// Wraps setKDPAttribute:propertyName:value: method by block syntax.
@property (nonatomic, copy, readonly) void (^setKDPAttribute)(NSString *pluginName, NSString *propertyName, NSString *value);

/// Wraps triggerEvent:withValue: method by block syntax.
@property (nonatomic, copy, readonly) void (^triggerEvent)(NSString *event, NSString *value);

/* The device manager used for the currently casting media. */
@property(weak, nonatomic) ChromecastDeviceController *castDeviceController;

@end

