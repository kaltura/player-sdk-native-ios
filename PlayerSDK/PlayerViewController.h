//
//  PlayerViewController.h
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

#import <MediaPlayer/MediaPlayer.h>
#import "PlayerSDK/PlayerControlsWebView.h"

typedef enum{
    src = 0,
    currentTime,
    visible,
    wvServerKey,
} Attribute;

@class NativeComponentPlugin;
@interface PlayerViewController : UIViewController <PlayerControlsWebViewDelegate> {
    MPMoviePlayerController *player;
    NativeComponentPlugin *delegate;
}

@property (nonatomic, strong) IBOutlet PlayerControlsWebView* webView;
@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, retain) NativeComponentPlugin *delegate;

- (void)setWebViewURL: (NSString *)iframeUrl;
- (void)stopAndRemovePlayer;
- (void)checkOrientationStatus;
- (void)resizePlayerView: (CGFloat )top right: (CGFloat )right width: (CGFloat )width height: (CGFloat )height;

@end

@interface NSString (EnumParser)
- (Attribute)attributeNameEnumFromString;
@end
