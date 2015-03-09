//
//  MyWebView.h
//  UIWebView-Call-ObjC
//
//  Created by NativeBridge on 02/09/10.
//

//This class is the HTML5 player, that rides over the native player

// Copyright (c) 2013 Kaltura, Inc. All rights reserved.
// License: http://corp.kaltura.com/terms-of-use
//


#import <UIKit/UIKit.h>


@protocol PlayerControlsWebViewDelegate <NSObject>
@required
- (void)handleHtml5LibCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args;
@end

@interface KPControlsWebView : UIWebView <UIWebViewDelegate> {
  
  int alertCallbackId;
}


@property (nonatomic, weak) id <PlayerControlsWebViewDelegate> playerControlsWebViewDelegate;

@property (nonatomic, assign, readonly) CGFloat videoHolderHeight;

@property (nonatomic, copy) NSString *entryId;


- (void)returnResult:(int)callbackId args:(id)firstObj, ...;

- (void)addEventListener:(NSString *)event;

- (void)removeEventListener:(NSString *)event;

- (void)evaluate:(NSString *)expression
      evaluateID:(NSString *)evaluateID;

- (void)sendNotification:(NSString *)notification
                withName:(NSString *)notificationName;

- (void)setKDPAttribute:(NSString *)pluginName
           propertyName:(NSString *)propertyName
                  value:(NSString *)value;

- (void)triggerEvent:(NSString *)event
           withValue:(NSString *)value;

- (void)triggerEvent:(NSString *)event withJSON:(NSString *)json;

- (void)updateLayout;
@end

