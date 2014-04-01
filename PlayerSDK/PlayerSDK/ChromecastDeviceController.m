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

#import "ChromecastDeviceController.h"
static NSString *const kReceiverAppID = @"DB6462E9";    //Movie player app

NSString *const ChromcastDeviceControllerDeviceConnectedNotification =
    @"ChromcastDeviceControllerDeviceConnectedNotification";
NSString *const ChromcastDeviceControllerDeviceDisconnectedNotification =
    @"ChromcastDeviceControllerDeviceDisconnectedNotification";
NSString *const ChromcastDeviceControllerMediaNowPlayingNotification =
    @"ChromcastDeviceControllerMediaNowPlayingNotification";
NSString *const ChromcastDeviceControllerSessionJoinNotification =
    @"ChromcastDeviceControl lerSessionJoinNotification";
NSString *const ChromcastDeviceControllerStatusChangedNotification =
    @"ChromcastDeviceControllerStatusChangedNotification";

@interface ChromecastDeviceController () {
  UIImage* _btnImage;
  UIImage* _btnImageSelected;

  dispatch_queue_t _queue;
}

@property GCKMediaControlChannel* mediaControlChannel;
@property GCKApplicationMetadata* applicationMetadata;
@property GCKDevice *selectedDevice;
@property float deviceVolume;
@property bool deviceMuted;
@end

@implementation ChromecastDeviceController

- (id)init {
  self = [super init];
  if (self) {
    //Initialize device scanner
    self.deviceScanner = [[GCKDeviceScanner alloc] init];

    //Create chromecast button
    _btnImage = [UIImage imageNamed:@"icon-cast-connected.png"];
    _btnImageSelected = [UIImage imageNamed:@"icon-cast-connected.png"];

//    _chromecastButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    [_chromecastButton addTarget:self
//                          action:@selector(chooseDevice:)
//                forControlEvents:UIControlEventTouchDown];
//    _chromecastButton.frame = CGRectMake(0, 0, 40, 40);
//      _chromecastButton.backgroundColor = [UIColor redColor];
//    [_chromecastButton setImage:nil forState:UIControlStateNormal];
//    _chromecastButton.hidden = YES;

    _queue = dispatch_queue_create("com.google.sample.Chromecast", NULL);

  }
  return self;
}

- (BOOL)isConnected {
  return self.deviceManager.isConnected;
}

- (void)performScan:(BOOL)start {

  if (start) {
    [self.deviceScanner addListener:self];
    [self.deviceScanner startScan];
  } else {
    [self.deviceScanner stopScan];
    [self.deviceScanner removeListener:self];
  }
}

- (void)connectToDevice {
  if (self.selectedDevice == nil)
    return;

  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  NSString *appIdentifier = [info objectForKey:@"CFBundleIdentifier"];
  self.deviceManager =
      [[GCKDeviceManager alloc] initWithDevice:self.selectedDevice clientPackageName:appIdentifier];
  self.deviceManager.delegate = self;
  [self.deviceManager connect];
}

- (void)chooseDevice:(id)sender {
  //Choose device
  if (self.selectedDevice == nil) {
    //Choose device
    UIActionSheet* sheet =
        [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Connect to Device", nil)
                                    delegate:self
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil];

    for (GCKDevice* device in self.deviceScanner.devices) {
      [sheet addButtonWithTitle:device.friendlyName];
    }

    [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;

    [ sheet showInView: [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] ];
  } else {
    // Gather stats from device.
    [self updateStatsFromDevice];

    //Offer disconnect option

    NSString* str = [NSString stringWithFormat:NSLocalizedString(@"Casting to %@", nil),
        self.selectedDevice.friendlyName];
    NSString* mediaTitle = self.mediaInformation.metadata.title;

    UIActionSheet* sheet = [[UIActionSheet alloc] init];
    sheet.title = str;
    sheet.delegate = self;
    if (mediaTitle != nil) {
      [sheet addButtonWithTitle:mediaTitle];
    }
    [sheet addButtonWithTitle:@"Disconnect"];
    [sheet addButtonWithTitle:@"Cancel"];
    sheet.destructiveButtonIndex = (mediaTitle != nil ? 1 : 0);
    sheet.cancelButtonIndex = (mediaTitle != nil ? 2 : 1);
    
    [ sheet showInView: [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject] ];
  }
}

- (void)updateButtonStates {
  if (self.deviceScanner.devices.count == 0) {
      [ [NSNotificationCenter defaultCenter] postNotificationName: @"hideChromecastButtonNotification"
                                                           object: self
                                                         userInfo: nil ];
      
    //Enable the button
//    [_chromecastButton setImage:_btnImage forState:UIControlStateNormal];
//    _chromecastButton.hidden = YES;
  } else {
      [ [NSNotificationCenter defaultCenter] postNotificationName: @"showChromecastButtonNotification"
                                                           object: self
                                                         userInfo: nil ];
      
    if (self.deviceManager && self.deviceManager.isConnected) {
      //Enable the button
//      [_chromecastButton setImage:_btnImageSelected forState:UIControlStateNormal];
//      [_chromecastButton setTintColor:nil];
//      _chromecastButton.hidden = NO;

    } else {
      //Enable the button
//      [_chromecastButton setImage:_btnImage forState:UIControlStateNormal];
//      [_chromecastButton setTintColor:[UIColor grayColor]];
//      _chromecastButton.hidden = NO;
    }
  }

}

- (void)updateStatsFromDevice {

  if (self.mediaControlChannel && self.isConnected) {
    _streamPosition = [self.mediaControlChannel approximateStreamPosition];
    _streamDuration = self.mediaControlChannel.mediaStatus.mediaInformation.streamDuration;

    _playerState = self.mediaControlChannel.mediaStatus.playerState;
    _mediaInformation = self.mediaControlChannel.mediaStatus.mediaInformation;

  }

}

- (void)changeVolumeIncrease:(BOOL)goingUp {
  float idealVolume = self.deviceVolume + (goingUp ? 0.1 : -0.1);
  idealVolume = MIN(1.0, MAX(0.0, idealVolume));

  [self.deviceManager setVolume:idealVolume];
}

- (void)setPlaybackPercent:(float)newPercent {
//  newPercent = MAX(MIN(1.0, newPercent), 0.0);

//  NSTimeInterval newTime = newPercent * _streamDuration;
  if (_streamDuration > 0 && self.isConnected) {
    [self.mediaControlChannel seekToTimeInterval: newPercent];
  }
}

- (void)pauseCastMedia:(BOOL)shouldPause {
  if (self.mediaControlChannel && self.isConnected) {
    if (shouldPause) {
      [self.mediaControlChannel pause];
    } else {
      [self.mediaControlChannel play];
    }
  }
}

- (void)stopCastMedia {
  if (self.mediaControlChannel && self.isConnected) {
    NSLog(@"Telling cast media control channel to stop");
    [self.mediaControlChannel stop];
  }
}


#pragma mark - GCKDeviceManagerDelegate


- (void)deviceManagerDidConnect:(GCKDeviceManager *)deviceManager {
  NSLog(@"connected!!");
  
  [self updateButtonStates];
  [self.deviceManager launchApplication:kReceiverAppID];
}


- (void)deviceManager:(GCKDeviceManager *)deviceManager didConnectToCastApplication:(GCKApplicationMetadata *)applicationMetadata sessionID:(NSString *)sessionID launchedApplication:(BOOL)launchedApplication {

  NSLog(@"application has launched");
  self.mediaControlChannel = [[GCKMediaControlChannel alloc] init];
  self.mediaControlChannel.delegate = self;
  [self.deviceManager addChannel:self.mediaControlChannel];
  [self.mediaControlChannel requestStatus];

  self.applicationMetadata = applicationMetadata;
  [self updateButtonStates];

  //Post notification
  [[NSNotificationCenter defaultCenter]
      postNotificationName:ChromcastDeviceControllerDeviceConnectedNotification
                    object:self];

}


- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didFailToLaunchCastApplicationWithError:(NSError *)error {
  [self showError:error];

  [self deviceDisconnected];
  [self updateButtonStates];
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager
    didFailToConnectWithError:(GCKError *)error {
  [self showError:error];

  [self deviceDisconnected];
  [self updateButtonStates];
}


- (void)deviceManager:(GCKDeviceManager *)deviceManager didDisconnectWithError:(GCKError *)error {
  NSLog(@"Received notification that device disconnected");

  if (error != nil) {
    [self showError:error];
  }

  [self deviceDisconnected];
  [self updateButtonStates];

}


- (void)deviceDisconnected {
  self.mediaControlChannel = nil;
  self.deviceManager = nil;
  self.selectedDevice = nil;
  //Post notification
  NSLog(@"Posting notification about the device being disconnected");
  [[NSNotificationCenter defaultCenter]
      postNotificationName:ChromcastDeviceControllerDeviceDisconnectedNotification
                    object:self];

}

- (void)deviceManager:(GCKDeviceManager *)deviceManager didReceiveStatusForApplication:(GCKApplicationMetadata *)applicationMetadata {
  self.applicationMetadata = applicationMetadata;
}

- (void)deviceManager:(GCKDeviceManager *)deviceManager volumeDidChangeToLevel:(float)volumeLevel isMuted:(BOOL)isMuted {
  NSLog(@"New volume level of %f reported!", volumeLevel);
  self.deviceVolume = volumeLevel;
  self.deviceMuted = isMuted;
}


#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(GCKDevice *)device {
    NSLog(@"device found -> %@", device.friendlyName);
   
    [self updateButtonStates];
}

- (void)deviceDidGoOffline:(GCKDevice *)device {
    NSLog(@"device went offline -> %@", device.friendlyName);

    [ [NSNotificationCenter defaultCenter] postNotificationName: @"chromecastDeviceDidGoOfflineNotification"
                                                         object: self
                                                       userInfo: nil ];
    
    [self updateButtonStates];
}

#pragma - GCKMediaControlChannelDelegate methods

- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
    didCompleteLoadWithSessionID:(NSInteger)sessionID {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:ChromcastDeviceControllerMediaNowPlayingNotification
                    object:self];
}

- (void)mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel {
  [self updateStatsFromDevice];
  NSLog(@"Media control channel status changed");
  [[NSNotificationCenter defaultCenter]
   postNotificationName:ChromcastDeviceControllerStatusChangedNotification
   object:self];
}

- (void)mediaControlChannelDidUpdateMetadata:(GCKMediaControlChannel *)mediaControlChannel {
  [self updateStatsFromDevice];
  NSLog(@"Media control channel metadata changed");
  [[NSNotificationCenter defaultCenter]
      postNotificationName:ChromcastDeviceControllerStatusChangedNotification
                    object:self];
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (self.selectedDevice == nil) {
    if (buttonIndex < self.deviceScanner.devices.count) {
      self.selectedDevice = self.deviceScanner.devices[buttonIndex];
      NSLog(@"Selecting device:%@", self.selectedDevice.friendlyName);
      [self connectToDevice];
    }
  } else {
    if ( [[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Disconnect"] ) { //Disconnect button
      NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
      // New way of doing things: We're not going to stop the applicaton. We're just going
      // to leave it.
      [self.deviceManager leaveApplication];
      // If you want to force application to stop, uncomment below
      //[self.deviceManager stopApplicationWithSessionID:self.applicationMetadata.sessionID];
      [self.deviceManager disconnect];

      // Hack I need to put in for now, because deviceDisconnected doesn't appear to be getting called
      [self deviceDisconnected];
      [self updateButtonStates];
    } else if ( buttonIndex == [actionSheet cancelButtonIndex] ) { // Join the existing session.
      [[NSNotificationCenter defaultCenter]
       postNotificationName:ChromcastDeviceControllerSessionJoinNotification
       object:self];
    }
  }
}

- (BOOL)loadMedia:(NSURL *)url
     thumbnailURL:(NSURL *)thumbnailURL
            title:(NSString *)title
         subtitle:(NSString *)subtitle
         mimeType:(NSString *)mimeType
        startTime:(NSTimeInterval)startTime
         autoPlay:(BOOL)autoPlay {
  if (!self.deviceManager || !self.deviceManager.isConnected) {
    return NO;
  }

  GCKMediaMetadata *metadata = [[GCKMediaMetadata alloc] init];
  if (title != nil) {
    metadata.title = title;
  }

  if (subtitle != nil) {
    metadata.subtitle = subtitle;
  }

  if (thumbnailURL != nil) {
     [metadata addMediaImage:[[GCKImage alloc] initWithURL:thumbnailURL width:200 height:100]];
  }

  GCKMediaInformation *mediaInformation =
      [[GCKMediaInformation alloc] initWithContentID:[url absoluteString]
                                          streamType:GCKMediaStreamTypeNone
                                         contentType:mimeType
                                            metadata:metadata
                                      streamDuration:0
                                          customData:nil];
  [_mediaControlChannel loadMedia:mediaInformation autoplay:autoPlay playPosition:startTime];

  return YES;
}


#pragma mark - misc
- (void)showError:(NSError *)error {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                  message:NSLocalizedString(error.description, nil)
                                                 delegate:nil
                                        cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                        otherButtonTitles:nil];
  [alert show];
}

- (NSString*)getDeviceName {
  if (self.selectedDevice == nil)
    return @"";
  return self.selectedDevice.friendlyName;
}

@end

