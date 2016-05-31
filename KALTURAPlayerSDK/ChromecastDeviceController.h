// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and


#import "KChromeCastWrapper.h"
@interface ChromecastDeviceController : NSObject <
    KPGCDeviceScannerListener
>

/**
 *  The storyboard contianing the Cast component views used by the controllers in
 *  the CastComponents group.
 */
//@property(nonatomic, readonly) UIStoryboard *storyboard;

/**
 *  The delegate for this object.
 */
@property(nonatomic, weak) id<ChromecastDeviceControllerDelegate> delegate;

/**
 *  The Cast application ID to launch.
 */
@property(nonatomic, copy) NSString *applicationID;

/**
 *  The device manager used to manage a connection to a Cast device.
 */
@property(nonatomic, strong) id<KPGCDeviceManager> deviceManager;

/**
 *  The device scanner used to detect devices on the network.
 */
@property(nonatomic, strong) id<KPGCDeviceScanner> deviceScanner;

/**
 *  The media information of the loaded media on the device.
 */
@property(nonatomic, strong) id<KPGCMediaInformation> mediaInformation;

/** 
 *  The media control channel for the playing media. 
 */
@property (nonatomic, strong) id<KPGCMediaControlChannel> mediaControlChannel;

/**
 *  Helper accessor for the media player state of the media on the device.
 */
@property(nonatomic, readonly) KPGCMediaPlayerState playerState;

/**
 * The current idle reason. This value is only meaningful if the player state is
 * KPGCMediaPlayerStateIdle.
 */
@property(nonatomic, readonly) KPGCMediaPlayerIdleReason idleReason;

/**
 *  Helper accessor for the duration of the currently casting media.
 */
@property(nonatomic, readonly) NSTimeInterval streamDuration;

/**
 *  The current playback position of the currently casting media.
 */
@property(nonatomic, readonly) NSTimeInterval streamPosition;

/**
 *  Main access point for the class. Use this to retrieve an object you can use.
 *
 *  @return ChromecastDeviceController
 */
+ (instancetype)sharedInstance;

/**
 *  Sets the position of the playback on the Cast device.
 *
 *  @param newPercent 0.0-1.0
 */
- (void)setPlaybackPercent:(float)newPercent;

/**
 *  Connect to the given Cast device.
 *
 *  @param device A GCKDevice from the deviceScanner list.
 */
- (void)connectToDevice:(id<KPGCDevice>)device;

/**
 *  Load media onto the currently connected device.
 *
 *  @param media     The GCKMediaInformation to play, with the URL as the contentID
 *  @param startTime Time to start from if starting a fresh cast
 *  @param autoPlay  Whether to start playing as soon as the media is loaded.
 *
 *  @return YES if we can load the media.
 */
- (BOOL)loadMedia:(id<KPGCMediaInformation>)media
        startTime:(NSTimeInterval)startTime
         autoPlay:(BOOL)autoPlay;

/** 
 *  Enable Cast enhancing of the controller by adding icons
 *  and other UI elements. Signals that this view controller should be 
 *  used for presenting UI elements.
 *
 *  @param controller The UIViewController to decorate.
 */
//- (void)decorateViewController:(UIViewController *)controller;

/**
 *  Request an update for the minicontroller toolbar. Passed UIViewController must have a
 *  toolbar - for example if it is under a UINavigationBar.
 *
 *  @param viewController UIViewController to update the toolbar on.
 */
//- (void)updateToolbarForViewController:(UIViewController *)viewController;

/**
 *  Return the last known stream position for the given contentID. This will generally only
 *  be useful for the last Cast media, and allows a local player to resume playback at the
 *  position noted before disconnect. In many cases it will return 0.
 *
 *  @param contentID The string of the identifier of the media to be displayed.
 *
 *  @return the position in the stream of the media, if any.
 */
- (NSTimeInterval)streamPositionForPreviouslyCastMedia:(NSString *)contentID;

/**
 *  Prevent automatically reconnecting to the Cast device if we see it again.
 */
- (void)clearPreviousSession;

/**
 *  Enable basic logging of all GCKLogger messages to the console.
 */
- (void)enableLogging;

@end