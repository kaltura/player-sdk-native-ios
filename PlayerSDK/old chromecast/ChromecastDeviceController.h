// Copyright 2013 Google Inc. All Rights Reserved.
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
// limitations under the License.

#import <UIKit/UIKit.h>
#import <GoogleCast/GoogleCast.h>
#import <Foundation/Foundation.h>

//Posted when the device is ready to cast
NSString *const ChromcastDeviceControllerDeviceConnectedNotification;

//Posted when the device is disconencted
NSString *const ChromcastDeviceControllerDeviceDisconnectedNotification;

//Posted when loaded media starts playing
NSString *const ChromcastDeviceControllerMediaNowPlayingNotification;

//Posted when joining existing media session.
NSString *const ChromcastDeviceControllerSessionJoinNotification;

//Posted when another user replaces the playing session.
NSString *const ChromcastDeviceControllerStatusChangedNotification;

@interface ChromecastDeviceController : NSObject<GCKDeviceScannerListener,
                                                GCKDeviceManagerDelegate,
                                                GCKMediaControlChannelDelegate,
                                                UIActionSheetDelegate>
@property (nonatomic, strong) GCKDeviceScanner* deviceScanner;
//@property (nonatomic, strong) UIButton* chromecastButton;
@property (nonatomic, strong) GCKDeviceManager* deviceManager;
@property (readonly, getter = getDeviceName) NSString* deviceName;
@property (nonatomic, readonly) NSTimeInterval streamDuration;
@property (nonatomic, readonly) NSTimeInterval streamPosition;
@property (nonatomic, readonly) GCKMediaPlayerState playerState;
@property (nonatomic, readonly) GCKMediaInformation *mediaInformation;


- (void)performScan:(BOOL)start;
- (BOOL)loadMedia:(NSURL*)url
     thumbnailURL:(NSURL*) thumbnailURL
            title:(NSString*) title
         subtitle:(NSString*) subtitle
         mimeType:(NSString*) mimeType
        startTime:(NSTimeInterval) startTime
         autoPlay:(BOOL) autoPlay;

- (BOOL)isConnected;
- (void)pauseCastMedia:(BOOL)shouldPause;
- (void)updateStatsFromDevice;
- (void)setPlaybackPercent:(float)newPercent;
- (void)stopCastMedia;
- (void)changeVolume: (float)idealVolume;
- (void)chooseDevice:(id)sender;

@end


