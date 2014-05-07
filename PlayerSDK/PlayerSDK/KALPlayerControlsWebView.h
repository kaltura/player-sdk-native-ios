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

@protocol KALPlayerControlsWebViewDelegate <NSObject>
@required
- (void)handleHtml5LibCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args;
@end

@interface KALPlayerControlsWebView : UIWebView <UIWebViewDelegate> {
  
  int alertCallbackId;
   __unsafe_unretained id <KALPlayerControlsWebViewDelegate> playerControlsWebViewDelegate;
}

@property (nonatomic, assign) id <KALPlayerControlsWebViewDelegate> playerControlsWebViewDelegate;

- (void)handleCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args;
- (void)returnResult:(int)callbackId args:(id)firstObj, ...;

@end

