//
//  KChromeCastWrapper.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 31/05/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @enum KPGCConnectionState
 * Enum defining GCKDeviceManager connection states.
 */
typedef NS_ENUM(NSInteger, KPGCConnectionState) {
    /** Disconnected from the device or application. */
    KPGCConnectionStateDisconnected = 0,
    /** Connecting to the device or application. */
    KPGCConnectionStateConnecting = 1,
    /** Connected to the device or application. */
    KPGCConnectionStateConnected = 2,
    /** Disconnecting from the device. */
    KPGCConnectionStateDisconnecting = 3
};

/**
 * @enum KPGCMediaStreamType
 * Enum defining the media stream type.
 */
typedef NS_ENUM(NSInteger, KPGCMediaStreamType) {
    /** A stream type of "none". */
    KPGCMediaStreamTypeNone = 0,
    /** A buffered stream type. */
    KPGCMediaStreamTypeBuffered = 1,
    /** A live stream type. */
    KPGCMediaStreamTypeLive = 2,
    /** An unknown stream type. */
    KPGCMediaStreamTypeUnknown = 99,
};

/**
 * @enum KPGCErrorCode
 * Description of error codes
 */
typedef NS_ENUM(NSInteger, KPGCErrorCode) {
    /**
     * Error Code indicating no error.
     */
    KPGCErrorCodeNoError = 0,
    
    /**
     * Error code indicating a network I/O error.
     */
    KPGCErrorCodeNetworkError = 1,
    
    /**
     * Error code indicating that an operation has timed out.
     */
    KPGCErrorCodeTimeout = 2,
    
    /**
     * Error code indicating an authentication error.
     */
    KPGCErrorCodeDeviceAuthenticationFailure = 3,
    
    /**
     * Error code indicating that an invalid request was made.
     */
    KPGCErrorCodeInvalidRequest = 4,
    
    /**
     * Error code indicating that an in-progress request has been cancelled, most likely because
     * another action has preempted it.
     */
    KPGCErrorCodeCancelled = 5,
    
    /**
     * Error code indicating that a request has been replaced by another request of the same type.
     */
    KPGCErrorCodeReplaced = 6,
    
    /**
     * Error code indicating that the request was disallowed and could not be completed.
     */
    KPGCErrorCodeNotAllowed = 7,
    
    /**
     * Error code indicating that a request could not be made because the same type of request is
     * still in process.
     */
    KPGCErrorCodeDuplicateRequest = 8,
    
    /**
     * Error code indicating that the request is not allowed in the current state.
     */
    KPGCErrorCodeInvalidState = 9,
    
    /**
     * Error code indicating that a requested application could not be found.
     */
    KPGCErrorCodeApplicationNotFound = 20,
    
    /**
     * Error code indicating that a requested application is not currently running.
     */
    KPGCErrorCodeApplicationNotRunning = 21,
    
    /**
     * Error code indicating that the application session ID was not valid.
     */
    KPGCErrorCodeInvalidApplicationSessionID = 22,
    
    /**
     * Error code indicating that a media load failed on the receiver side.
     */
    KPGCErrorCodeMediaLoadFailed = 30,
    
    /**
     * Error code indicating that a media media command failed because of the media player state.
     */
    KPGCErrorCodeInvalidMediaPlayerState = 31,
    
    /**
     * Error code indicating the app entered the background.
     */
    KPGCErrorCodeAppDidEnterBackground = 91,
    
    /**
     * Error code indicating a disconnection occurred during the request.
     */
    KPGCErrorCodeDisconnected = 92,
    
    /**
     * Error code indicating that an unknown, unexpected error has occurred.
     */
    KPGCErrorCodeUnknown = 99,
};


/**
 * @enum KPGCMediaPlayerIdleReason
 * Media player idle reasons.
 */
typedef NS_ENUM(NSInteger, KPGCMediaPlayerIdleReason) {
    /** Constant indicating that the player currently has no idle reason. */
    KPGCMediaPlayerIdleReasonNone = 0,
    
    /** Constant indicating that the player is idle because playback has finished. */
    KPGCMediaPlayerIdleReasonFinished = 1,
    
    /**
     * Constant indicating that the player is idle because playback has been cancelled in
     * response to a STOP command.
     */
    KPGCMediaPlayerIdleReasonCancelled = 2,
    
    /**
     * Constant indicating that the player is idle because playback has been interrupted by
     * a LOAD command.
     */
    KPGCMediaPlayerIdleReasonInterrupted = 3,
    
    /** Constant indicating that the player is idle because a playback error has occurred. */
    KPGCMediaPlayerIdleReasonError = 4,
};


typedef NS_ENUM(NSInteger, KPGCMediaPlayerState) {
    /** Constant indicating unknown player state. */
    KPGCMediaPlayerStateUnknown = 0,
    /** Constant indicating that the media player is idle. */
    KPGCMediaPlayerStateIdle = 1,
    /** Constant indicating that the media player is playing. */
    KPGCMediaPlayerStatePlaying = 2,
    /** Constant indicating that the media player is paused. */
    KPGCMediaPlayerStatePaused = 3,
    /** Constant indicating that the media player is buffering. */
    KPGCMediaPlayerStateBuffering = 4,
};


@protocol KPGCDevice <NSObject>
@property(nonatomic, copy) NSString *deviceID;
@property(nonatomic, copy) NSString *friendlyName;
@property(nonatomic, copy, readonly) NSString *ipAddress;
@property(nonatomic, readonly) UInt32 servicePort;
@end

@protocol KPGCMediaInformation;
@protocol KPGCMediaStatus <NSObject>
@property(nonatomic, readonly) KPGCMediaPlayerState playerState;
/**
 * Gets the current stream playback rate. This will be negative if the stream is seeking
 * backwards, 0 if the stream is paused, 1 if the stream is playing normally, and some other
 * postive value if the stream is seeking forwards.
 */
@property(nonatomic, readonly) float playbackRate;
@property(nonatomic, readonly) KPGCMediaPlayerIdleReason idleReason;
@property(nonatomic, strong, readonly) id<KPGCMediaInformation> mediaInformation;
@end

@protocol KPGCMediaControlChannel <NSObject>
@property(nonatomic, strong, readonly) id<KPGCMediaStatus> mediaStatus;
@property(nonatomic, weak) id delegate;
- (NSTimeInterval)approximateStreamPosition;
- (NSInteger)seekToTimeInterval:(NSTimeInterval)position;
- (NSInteger)requestStatus;
- (NSInteger)loadMedia:(id<KPGCMediaInformation>)mediaInfo
              autoplay:(BOOL)autoplay
          playPosition:(NSTimeInterval)playPosition;
- (void)play;
- (void)pause;
- (NSInteger)stop;
- (NSInteger)setStreamVolume:(float)volume;
- (NSInteger)setStreamMuted:(BOOL)muted;
@end

@protocol KPGCLaunchOptions <NSObject>

/** Initializes the object with the system's language and the given relaunch behavior. */
- (instancetype)initWithRelaunchIfRunning:(BOOL)relaunchIfRunning;

@end

@protocol KPGCDeviceManager <NSObject>
@property(nonatomic, readonly) id<KPGCDevice> device;
@property(nonatomic, weak) id delegate;
@property(nonatomic, readonly) KPGCConnectionState applicationConnectionState;
//- (instancetype)initWithDevice:(id<KPGCDevice>)device clientPackageName:(NSString *)clientPackageName;
- (instancetype)initWithDevice:(id<KPGCDevice>)device
             clientPackageName:(NSString *)clientPackageName
   ignoreAppStateNotifications:(BOOL)ignoreAppStateNotifications;
- (NSInteger)stopApplicationWithSessionID:(NSString *)sessionID;
- (void)connect;
- (void)disconnect;
- (BOOL)leaveApplication;
- (void)disconnectWithLeave:(BOOL)leaveApplication;
- (NSInteger)launchApplication:(NSString *)applicationID;
- (NSInteger)launchApplication:(NSString *)applicationID
             withLaunchOptions:(id<KPGCLaunchOptions>)launchOptions;
- (BOOL)addChannel:(id)channel;
- (BOOL)removeChannel:(id)channel;
- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager
didDisconnectWithError:(NSError *)error;
@end

@protocol KPGCDeviceScannerListener;

@protocol KPGCDeviceScanner <NSObject>
//- (id)initWithFilterCriteria:(id)criteria;
- (void)addListener:(id<KPGCDeviceScannerListener>)listener;
@property(nonatomic, readonly, copy) NSArray<id<KPGCDevice>> *devices;
@property (nonatomic) BOOL passiveScan;
- (void)startScan;
- (void)stopScan;
@end

@protocol KPGCMediaMetadata <NSObject>
- (NSString *)stringForKey:(NSString *)key;
@end

@protocol KPGCMediaInformation <NSObject>
@property(nonatomic, strong, readonly) id<KPGCMediaMetadata> metadata;
@property(nonatomic, readonly) NSTimeInterval streamDuration;
@property(nonatomic, copy, readonly) NSString *contentID;
@property(nonatomic, copy, readonly) NSString *contentType;
- (instancetype)initWithContentID:(NSString *)contentID
                       streamType:(KPGCMediaStreamType)streamType
                      contentType:(NSString *)contentType
                         metadata:(id<KPGCMediaMetadata>)metadata
                   streamDuration:(NSTimeInterval)streamDuration
                       customData:(id)customData;
@end



@protocol KPGCApplicationMetadata <NSObject>
@property(nonatomic, strong, readonly) id<KPGCMediaMetadata> metadata;
@end

@protocol KPGCError <NSObject>
@property (readonly) NSInteger code;
@end


@protocol KCastChannel <NSObject>

- (BOOL)sendTextMessage:(NSString *)message;

@end

@protocol KPGCDeviceScannerListener <NSObject>

@optional

/**
 * Called when a device has been discovered or has come online.
 *
 * @param device The device.
 */
- (void)deviceDidComeOnline:(id<KPGCDevice>)device;

/**
 * Called when a device has gone offline.
 *
 * @param device The device.
 */
- (void)deviceDidGoOffline:(id<KPGCDevice>)device;

/**
 * Called when there is a change to one or more properties of the device that do not affect
 * connectivity to the device. This includes all properties except the device ID, IP address,
 * and service port; if any of these properties changes, the device will be reported as "offline"
 * and a new device with the updated properties will be reported as "online".
 *
 * @param device The device.
 */
- (void)deviceDidChange:(id<KPGCDevice>)device;

@end

@protocol KPGCCastChannel <NSObject>
@optional
/** The channel's namespace. */
@property(nonatomic, copy, readonly) NSString *protocolNamespace;

/** A flag indicating whether this channel is currently connected. */
@property(nonatomic, readonly) BOOL isConnected;

/** The device manager with which this channel is registered, if any. */
@property(nonatomic, weak, readonly) id<KPGCDeviceManager> deviceManager;

/**
 * Designated initializer. Constructs a new GCKCastChannel with the given namespace.
 *
 * @param protocolNamespace The namespace.
 */
- (instancetype)initWithNamespace:(NSString *)protocolNamespace;

/**
 * Called when a text message has been received on this channel. The default implementation is a
 * no-op.
 *
 * @param message The message.
 */
- (void)didReceiveTextMessage:(NSString *)message;

/**
 * Sends a text message on this channel.
 *
 * @param message The message.
 * @return <code>YES</code> on success or <code>NO</code> if the message could not be sent (because
 * the channel is not connected, or because the send buffer is too full at the moment).
 */
- (BOOL)sendTextMessage:(NSString *)message;

/**
 * Sends a text message on this channel.
 *
 * @param message The message.
 * @param error A pointer at which to store the error result. May be nil.
 * @return <code>YES</code> on success or <code>NO</code> if the message could not be sent.
 */
//- (BOOL)sendTextMessage:(NSString *)message
//                  error:(GCKError **)error;

/**
 * Generates a request ID for a new message.
 *
 * @return The generated ID, or <code>kGCKInvalidRequestID</code> if the channel is not currently
 * connected.
 */
- (NSInteger)generateRequestID;

/**
 * A convenience method which wraps generateRequestID in an NSNumber.
 *
 * @return The generated ID, or <code>nil</code> if the channel is not currently connected.
 */
- (NSNumber *)generateRequestNumber;

/**
 * Called when this channel has been connected, indicating that messages can now be exchanged with
 * the Cast device over this channel. The default implementation is a no-op.
 */
- (void)didConnect;

/**
 * Called when this channel has been disconnected, indicating that messages can no longer be
 * exchanged with the Cast device over this channel. The default implementation is a no-op.
 */
- (void)didDisconnect;

@end

// limitations under the License.

#import <Foundation/Foundation.h>

extern NSString * const kCastViewController;

@protocol ChromecastDeviceControllerDelegate <NSObject>

@optional

/**
 * Called when connection to the device was established.
 *
 * @param device The device to which the connection was established.
 */
- (void)didConnectToDevice:(id<KPGCDevice>)device;

/**
 *  Called when the device disconnects.
 */
- (void)didDisconnect;

/**
 * Called when Cast devices are discoverd on the network.
 */
- (void)didDiscoverDeviceOnNetwork;

/**
 * Called when Cast device is connecting
 */
- (void)castConnectingToDevice;

/**
 * Called when a request to load media has completed.
 */
- (void)didCompleteLoadWithSessionID:(NSInteger)sessionID;

/**
 * Called when updated player status information is received.
 */
- (void)didUpdateStatus:(id<KPGCMediaControlChannel>)mediaControlChannel;

@end

