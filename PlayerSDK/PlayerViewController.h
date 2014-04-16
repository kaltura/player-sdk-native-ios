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

//Chromecast
#import "PlayerSDK/ChromecastDeviceController.h"

typedef enum{
    // Player Content Source Url
    src = 0,
    // Player Current time (Progress Bar)
    currentTime,
    // Player Visibility
    visible,
  #if !(TARGET_IPHONE_SIMULATOR)
        // DRM WideVine Key
        wvServerKey,
    #endif
} Attribute;

@protocol KalturaPlayer <NSObject>

@required

@property double currentPlaybackTime;
@property(readonly) UIView * view;
@property int controlStyle;
@property(readonly) int playbackState;
@property(readonly) int loadState;
@property(readonly) BOOL isPreparedToPlay;
@property(copy) NSURL *contentURL;

- (void)pause;
- (void)play;
- (void)stop;
- (id)view;
- (double)currentPlaybackTime;
- (int)controlStyle;
- (int)playbackState;
- (int)loadState;
- (void)prepareToPlay;
- (BOOL)isPreparedToPlay;
- (void)setContentURL:(NSURL *)arg1;
- (double)playableDuration;
- (double)duration;

@end

@class NativeComponentPlugin;
@interface PlayerViewController : UIViewController <PlayerControlsWebViewDelegate> {
    id<KalturaPlayer> player;
    NativeComponentPlugin *delegate;
}

@property (nonatomic, strong) IBOutlet PlayerControlsWebView* webView;
//@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, strong) id<KalturaPlayer> player;
@property (nonatomic, retain) NativeComponentPlugin *delegate;

- (void)setWebViewURL: (NSString *)iframeUrl;
- (void)stopAndRemovePlayer;
- (void)checkOrientationStatus;
- (void)resizePlayerView: (CGFloat )top right: (CGFloat )right width: (CGFloat )width height: (CGFloat )height;
- (void)openFullScreen: (BOOL)openFullScreen;
- (void)checkDeviceStatus;

@end

@interface NSString (EnumParser)

- (Attribute)attributeNameEnumFromString;

@end