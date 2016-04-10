//
//  KPController_Private.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 7/26/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPController.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KPLog.h"
#import "NSString+Utilities.h"

NSString *sendNotification(NSString *notification, NSString *params);
NSString *setKDPAttribute(NSString *pluginName, NSString *propertyName, NSString *value);
NSString *triggerEvent(NSString *event, NSString *value);
NSString *triggerEventWithJSON(NSString *event, NSString *jsonString);
NSString *asyncEvaluate(NSString *expression, NSString *evaluateID);
NSString *showChromecastComponent(BOOL show);

@protocol KPControllerDelegate <NSObject>

/*!
 @method        sendKPNotification:withParams:
 @abstract      Call a KDP notification (perform actions using this API, for example: play, pause, changeMedia, etc.) (required)
 */

- (NSTimeInterval)duration;
- (NSTimeInterval)currentPlaybackTime;
- (float)volume;
- (void)setVolume:(float)value;
- (BOOL)mute;
- (void)setMute:(BOOL)isMute;

- (void)handleHtml5LibCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args;
- (void)handleKPControlsError:(NSError *)error;

@end

@protocol KPController <NSObject>

@property (nonatomic, weak) id<KPControllerDelegate> controlsDelegate;
@property (nonatomic, copy) NSString *entryId;
@property (nonatomic) BOOL shouldUpdateLayout;
//@property (nonatomic, assign, readonly) CGFloat videoHolderHeight;
@property (nonatomic) CGRect controlsFrame;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)loadRequest:(NSURLRequest *)request;

- (void)addEventListener:(NSString *)event;

- (void)removeEventListener:(NSString *)event;

- (void)evaluate:(NSString *)expression
      evaluateID:(NSString *)evaluateID;

- (void)sendNotification:(NSString *)notification
              withParams:(NSString *)params;

- (void)setKDPAttribute:(NSString *)pluginName
           propertyName:(NSString *)propertyName
                  value:(NSString *)value;

- (void)triggerEvent:(NSString *)event
           withValue:(NSString *)value;

- (void)triggerEvent:(NSString *)event withJSON:(NSString *)json;

- (void)updateLayout;

- (void)removeControls;

- (void)fetchvideoHolderHeight:(void(^)(CGFloat height))fetcher;

- (void)reset;

@optional
- (void)showChromecastComponent:(BOOL)show;

@end

@interface KPController ()
@property (nonatomic, readwrite) KPMediaPlaybackState playbackState;
@property (nonatomic, weak) id<KPControllerDelegate> delegate;
+ (id<KPController>)defaultControlsViewWithFrame:(CGRect)frame;
@end
