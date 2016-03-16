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
// limitations under the License.


#import "ChromecastDeviceController.h"
#import "KPLog.h"



/**
 *  Constant for the storyboard ID for the device table view controller.
 */
static NSString * const kDeviceTableViewController = @"deviceTableViewController";

/**
 *  Constant for the storyboard ID for the expanded view Cast controller.
 */
NSString * const kCastViewController = @"castViewController";

@interface ChromecastDeviceController()


/**
 *  The core storyboard containing the UI for the Cast components.
 */
//@property(nonatomic, readwrite) UIStoryboard *storyboard;
//
///**
// *  The (optional) view controller that we are managing.
// */
//@property(nonatomic) UIViewController *controller;
//
///**
// *  The Cast Icon Button controlled by this class.
// */
//@property(nonatomic) CastIconBarButtonItem *castIconButton;
//
///**
// *  The Cast Mini Controller controlled by this class.
// */
//@property(nonatomic) CastMiniController *castMiniController;

/**
 *  Whehter we are automatically adding the toolbar.
 */
@property(nonatomic) BOOL manageToolbar;

/**
 *  Whether or not we are attempting reconnect.
 */
@property(nonatomic) BOOL isReconnecting;

/**
 *  The last played content identifier.
 */
@property(nonatomic) NSString *lastContentID;

/**
 *  The last known playback position of the last played content.
 */
@property(nonatomic) NSTimeInterval lastPosition;
     
@end
      
@implementation ChromecastDeviceController
      
#pragma mark - Lifecycle

+ (instancetype)sharedInstance {
    if (!NSClassFromString(@"GCKDeviceScanner")) {
        return nil;
    }
  static dispatch_once_t p = 0;
  __strong static id _sharedDeviceController = nil;

  dispatch_once(&p, ^{
    _sharedDeviceController = [[self alloc] init];
  });

  return _sharedDeviceController;
  }

- (instancetype)init {
  self = [super init];
  if (self) {
    // Initialize UI controls for navigation bar and tool bar.
    [self initControls];

    // Load the storyboard for the Cast component UI.
//    self.storyboard = [UIStoryboard storyboardWithName:@"CastComponents" bundle:nil];
  }
  return self;
}

# pragma mark - Acessors

- (KPGCMediaPlayerState)playerState {
  return _mediaControlChannel.mediaStatus.playerState;
}

- (KPGCMediaPlayerIdleReason)playerIdleReason{
    return _mediaControlChannel.mediaStatus.idleReason;
  }

- (NSTimeInterval)streamDuration {
  return _mediaInformation.streamDuration;
}

- (NSTimeInterval)streamPosition {
  self.lastPosition = [_mediaControlChannel approximateStreamPosition];
  return self.lastPosition;
}

- (void)setPlaybackPercent:(float)newPercent {
  newPercent = MAX(MIN(1.0, newPercent), 0.0);

  NSTimeInterval newTime = newPercent * self.streamDuration;
  if (newTime > 0 )// && _deviceManager.applicationConnectionState == GCKConnectionStateConnected) {
    [self.mediaControlChannel seekToTimeInterval:newTime];
//}
}


/**
 *  Set the application ID and initialise a scan.
 *
 *  @param applicationID Cast application ID
 */
- (void)setApplicationID:(NSString *)applicationID {
    _applicationID = applicationID;
    self.deviceScanner = [NSClassFromString(@"GCKDeviceScanner") new];

    // Always start a scan as soon as we have an application ID.
    KPLogChromeCast(@"Starting Scan");
    [self.deviceScanner addListener:self];
    [self.deviceScanner startScan];
}

# pragma mark - UI Management

- (void)dismissDeviceTable {
//  [self.controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateCastIconButtonStates {
//  if (self.deviceManager.applicationConnectionState == GCKConnectionStateConnected) {
//    _castIconButton.status = CIBCastConnected;
//  } else if (self.deviceManager.applicationConnectionState == GCKConnectionStateConnecting) {
//    _castIconButton.status = CIBCastConnecting;
//  } else if (self.deviceScanner.devices.count == 0) {
//    _castIconButton.status = CIBCastUnavailable;
//  } else {
//    _castIconButton.status = CIBCastAvailable;
    // Show cast icon. If this is the first time the cast icon is appearing, show an overlay with
    // instructions highlighting the cast icon.
//    if (self.controller) {
//      [CastInstructionsViewController showIfFirstTimeOverViewController:self.controller];
//    }
//  }

//  if (self.manageToolbar) {
//    [self updateToolbarForViewController:self.controller];
//  }
  }

- (void)initControls {
//  self.castIconButton = [CastIconBarButtonItem barButtonItemWithTarget:self
//                                                              selector:@selector(chooseDevice:)];
//  self.castMiniController = [[CastMiniController alloc] initWithDelegate:self];
    }

- (void)displayCurrentlyPlayingMedia {
//  if (self.controller) {
//    CastViewController *vc =
//        [_storyboard instantiateViewControllerWithIdentifier:kCastViewController];
//    [vc setMediaToPlay:self.mediaInformation];
//    [self.controller.navigationController pushViewController:vc animated:YES];
//  }
  }

#pragma mark - GCKDeviceManagerDelegate

- (void)deviceManagerDidConnect:(id<KPGCDeviceManager>)deviceManager {
//  BOOL appMatch = [deviceManager.applicationMetadata.applicationID isEqualToString:_applicationID];
//  if (!_isReconnecting || !appMatch) {
//    // Explicit connect request when a different app (or none) is Casting.
    [self.deviceManager launchApplication:_applicationID];
//  } else if (_isReconnecting &&
//             deviceManager.applicationMetadata.applicationID &&
//             !appMatch) {
//    // Implicit reconnect but an application other than ours is playing, disconnect.
//    [deviceManager disconnect];
//  } else {
//    // Reconnect, or our app is playing. Attempt to join our session if there.
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSString* lastSessionID = [defaults valueForKey:@"lastSessionID"];
//    [self.deviceManager joinApplication:_applicationID sessionID:lastSessionID];
//  }
//  [self updateCastIconButtonStates];
}

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager
    didConnectToCastApplication:(id<KPGCApplicationMetadata>)applicationMetadata
                      sessionID:(NSString *)sessionID
            launchedApplication:(BOOL)launchedApplication {
  self.mediaControlChannel = [[NSClassFromString(@"GCKMediaControlChannel") alloc] init];
  self.mediaControlChannel.delegate = self;
  [self.deviceManager addChannel:self.mediaControlChannel];
  [self.mediaControlChannel requestStatus];

//  [self updateCastIconButtonStates];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"castApplicationConnected"
                                                      object:self];

  if ([_delegate respondsToSelector:@selector(didConnectToDevice:)]) {
    [_delegate didConnectToDevice:deviceManager.device];
  }

  self.isReconnecting = NO;
  // Store sessionID in case of restart
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:sessionID forKey:@"lastSessionID"];
  [defaults setObject:deviceManager.device.deviceID forKey:@"lastDeviceID"];
  [defaults synchronize];
}

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager
    volumeDidChangeToLevel:(float)volumeLevel
                   isMuted:(BOOL)isMuted {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"castVolumeChanged" object:self];
  }

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager
    didFailToConnectToApplicationWithError:(NSError *)error {
  [self updateCastIconButtonStates];
}

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager
    didFailToConnectWithError:(id<KPGCError>)error {
  [self clearPreviousSession];

  [self updateCastIconButtonStates];
}

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager didDisconnectWithError:(id<KPGCError>)error {
  KPLogChromeCast(@"Received notification that device disconnected");

  if (!error || (
      error.code == KPGCErrorCodeDeviceAuthenticationFailure ||
      error.code == KPGCErrorCodeDisconnected ||
      error.code == KPGCErrorCodeApplicationNotFound)) {
    [self clearPreviousSession];
  }

  _mediaInformation = nil;
  [self updateCastIconButtonStates];

  if ([_delegate respondsToSelector:@selector(didDisconnect)]) {
    [_delegate didDisconnect];
}
}

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager
    didDisconnectFromApplicationWithError:(NSError *)error {
  KPLogChromeCast(@"Received notification that app disconnected");

  if (error) {
    KPLogChromeCast(@"Application disconnected with error: %@", error);
  }

  // If we've lost the app connection, tear down the device connection.
  [deviceManager disconnect];
}

# pragma mark - Reconnection

- (void)clearPreviousSession {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults removeObjectForKey:@"lastDeviceID"];
  [defaults synchronize];
}

- (NSTimeInterval)streamPositionForPreviouslyCastMedia:(NSString *)contentID {
  if ([contentID isEqualToString:_lastContentID]) {
    return _lastPosition;
}
  return 0;
}

#pragma mark - GCKDeviceScannerListener

- (void)deviceDidComeOnline:(id<KPGCDevice>)device {
  KPLogChromeCast(@"device found - %@", device.friendlyName);

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString* lastDeviceID = [defaults objectForKey:@"lastDeviceID"];
  if(lastDeviceID != nil && [[device deviceID] isEqualToString:lastDeviceID]){
    self.isReconnecting = YES;
    [self connectToDevice:device];
  }

  if ([_delegate respondsToSelector:@selector(didDiscoverDeviceOnNetwork)]) {
    [_delegate didDiscoverDeviceOnNetwork];
}

  [[NSNotificationCenter defaultCenter] postNotificationName:@"castScanStatusUpdated" object:self];
  [self updateCastIconButtonStates];
}

- (void)deviceDidGoOffline:(id<KPGCDevice>)device {
  KPLogChromeCast(@"device went offline - %@", device.friendlyName);
  [[NSNotificationCenter defaultCenter] postNotificationName:@"castScanStatusUpdated" object:self];
  [self updateCastIconButtonStates];
}

- (void)deviceDidChange:(id<KPGCDevice>)device {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"castScanStatusUpdated" object:self];
}

#pragma mark - GCKMediaControlChannelDelegate methods

- (void)mediaControlChannelDidUpdateStatus:(id<KPGCMediaControlChannel>)mediaControlChannel {
  KPLogChromeCast(@"Media control channel status changed");
  _mediaInformation = mediaControlChannel.mediaStatus.mediaInformation;
  self.lastContentID = _mediaInformation.contentID;
  [[NSNotificationCenter defaultCenter] postNotificationName:@"castMediaStatusChange" object:self];

    if ([_delegate respondsToSelector:@selector(didUpdateStatus:)]) {
        [_delegate didUpdateStatus:mediaControlChannel];
  }

//    [self updateCastIconButtonStates];
}

- (void)mediaControlChannelDidUpdateMetadata:(id<KPGCMediaControlChannel>)mediaControlChannel {
  KPLogChromeCast(@"Media control channel metadata changed");
  [[NSNotificationCenter defaultCenter] postNotificationName:@"castMediaStatusChange" object:self];
  }

- (void)mediaControlChannel:(id<KPGCMediaControlChannel>)mediaControlChannel didCompleteLoadWithSessionID:(NSInteger)sessionID {
    /// @todo maybe better use delegate
    KPLogChromeCast(@"Media control channel metadata changed");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"castApplicationCompleteLoadWithSessionID"
                                                        object:@{@"sessionID":@(sessionID)}];

    if ([_delegate respondsToSelector:@selector(didCompleteLoadWithSessionID:)]) {
        [_delegate didCompleteLoadWithSessionID:sessionID];
  }
  }

# pragma mark - Device & Media Management

- (void)connectToDevice:(id<KPGCDevice>)device {
  KPLogChromeCast(@"Connecting to device address: %@:%d", device.ipAddress, (unsigned int)device.servicePort);

  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  NSString *appIdentifier = [info objectForKey:@"CFBundleIdentifier"];
  self.deviceManager =
      [[NSClassFromString(@"GCKDeviceManager") alloc] initWithDevice:device clientPackageName:appIdentifier];
  self.deviceManager.delegate = self;
  [self.deviceManager connect];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"castConnectingToDevice"
                                                        object:nil];

    if ([_delegate respondsToSelector:@selector(castConnectingToDevice)]) {
        [_delegate castConnectingToDevice];
}
}

- (BOOL)loadMedia:(id<KPGCMediaInformation>)media
        startTime:(NSTimeInterval)startTime
         autoPlay:(BOOL)autoPlay {
//  if (!self.deviceManager || self.deviceManager.connectionState != GCKConnectionStateConnected ) {
//    return NO;
//}

  _mediaInformation = media;
  [self.mediaControlChannel loadMedia:media autoplay:autoPlay playPosition:startTime];

  return YES;
        }
        
//- (void)decorateViewController:(UIViewController *)controller {
//  self.controller = controller;
//  if (_controller) {
//    self.manageToolbar = false;
//    _controller.navigationItem.rightBarButtonItem = _castIconButton;
//    }
//  }
//
//- (void)updateToolbarForViewController:(UIViewController *)viewController {
//  self.manageToolbar = YES;
//  [self.castMiniController updateToolbarStateIn:viewController
//                            forMediaInformation:self.mediaInformation
//                                    playerState:self.playerState];
//    }

#pragma mark - GCKLoggerDelegate implementation

- (void)enableLogging {
  [[NSClassFromString(@"GCKLogger") sharedInstance] setDelegate:self];
}

- (void)logFromFunction:(const char *)function message:(NSString *)message {
  // Send SDK’s log messages directly to the console, as an example.
  KPLogChromeCast(@"%s  %@", function, message);
  }

@end