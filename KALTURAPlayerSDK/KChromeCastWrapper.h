//
//  KChromeCastWrapper.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 31/05/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol KPGError, KPGDevice, KPGCastDeviceStatusListener;

/**
 * @enum KPGCConnectionState
 * Enum defining KPGDeviceManager connection states.
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

/**
 * @enum KPGActiveInputStatus
 * An enum describing the active input status states. This status indicates whether a receiver
 * device is currently the active input on its connected TV or AVR.
 */
typedef NS_ENUM(NSInteger, KPGActiveInputStatus) {
    /** The active input status is unknown. */
    KPGActiveInputStatusUnknown = -1,
    /** The input is inactive. */
    KPGActiveInputStatusInactive = 0,
    /** The input is active. */
    KPGActiveInputStatusActive = 1,
};

/**
 * @enum KPGStandbyStatus
 * An enum describing the standby status states. This status indicates whether a receiver device's
 * connected TV or AVR is currently in "standby" mode.
 */
typedef NS_ENUM(NSInteger, KPGStandbyStatus) {
    /** The standby status is unknown.  */
    KPGStandbyStatusUnknown = -1,
    /** The device is not in standby mode.  */
    KPGStandbyStatusInactive = 0,
    /** The device is in standby mode.  */
    KPGStandbyStatusActive = 1,
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
@protocol KPGFilterCriteria;

@protocol KPGCDeviceScanner <NSObject>
//- (id)initWithFilterCriteria:(id)criteria;
/**
 * Designated initializer. Constructs a new KPGDeviceScanner with the given filter criteria.
 *
 * @param filterCriteria The filter criteria. May not be <code>nil</code>.
 */
- (instancetype)initWithFilterCriteria:(id<KPGFilterCriteria>)filterCriteria;

- (void)addListener:(id<KPGCDeviceScannerListener>)listener;
@property(nonatomic, readonly, copy) NSArray<id<KPGCDevice>> *devices;
@property (nonatomic) BOOL passiveScan;
- (void)startScan;
- (void)stopScan;
@end

@protocol KPGFilterCriteria <NSObject>

/**
 * Criteria for an application which is available to be launched on a device. The application does
 * not need to be currently running.
 *
 * @param applicationID The application ID. Must be non-nil.
 */
+ (instancetype)criteriaForAvailableApplicationWithID:(NSString *)applicationID;

/**
 * Criteria for an application which is currently running on the device and supports all of
 * the given namespaces.
 *
 * @param supportedNamespaces An array of namespace strings. May not be <code>nil</code>.
 */
+ (instancetype)criteriaForRunningApplicationWithSupportedNamespaces:
(NSArray<NSString *> *)supportedNamespaces;

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



/**
 * A class that represents an image that is located on a web server. Used for such things as
 * KPGDevice icons and KPGMediaMetadata artwork.
 */

@protocol KPGImage  <NSObject, NSCopying, NSCoding>

/**
 * The image URL.
 */
@property(nonatomic, strong, readonly) NSURL *URL;

/**
 * The image width, in pixels.
 */
@property(nonatomic, assign, readonly) NSInteger width;

/**
 * The image height, in pixels.
 */
@property(nonatomic, assign, readonly) NSInteger height;

/**
 * Constructs a new KPGImage with the given URL and dimensions. Designated initializer.
 *
 * @param URL The URL of the image.
 * @param width The width of the image, in pixels.
 * @param height The height of the image, in pixels.
 * @throw NSInvalidArgumentException if the URL is <code>nil</code> or empty, or the dimensions are
 * invalid.
 */
- (instancetype)initWithURL:(NSURL *)URL width:(NSInteger)width height:(NSInteger)height;

@end


/**
 * @enum KPGSenderApplicationInfoPlatform
 * Sender application platforms.
 */
typedef NS_ENUM(NSInteger, KPGSenderApplicationInfoPlatform) {
    /** Android. */
    KPGSenderApplicationInfoPlatformAndroid = 1,
    /** iOS. */
    KPGSenderApplicationInfoPlatformiOS = 2,
    /** Chrome. */
    KPGSenderApplicationInfoPlatformChrome = 3,
    /** Mac OS X. */
    KPGSenderApplicationInfoPlatformOSX = 4,
};

/**
 * Information about a sender application.
 */

//@interface KPGSenderApplicationInfo : NSObject <NSCopying>

@protocol KPGSenderApplicationInfo  <NSObject, NSCopying>

/** The sender application's platform. */
@property(nonatomic, assign, readonly) KPGSenderApplicationInfoPlatform platform;

/** The sender application's unique identifier (app ID). */
@property(nonatomic, copy, readonly) NSString *appIdentifier;

/** The sender application's launch URL (URL scheme). */
@property(nonatomic, strong, readonly) NSURL *launchURL;

@end


@protocol KPGApplicationMetadata  <NSObject, NSCopying>

/** The application's unique ID. */
@property(nonatomic, copy, readonly) NSString *applicationID;

/** The application's name, in a format that is appropriate for display. */
@property(nonatomic, copy, readonly) NSString *applicationName;

/** Any icon images for the application, as an array of KPGImage objects. */
@property(nonatomic, copy, readonly) NSArray<id<KPGImage>> *images;

/** The set of protocol namespaces supported by this application. */
@property(nonatomic, copy, readonly) NSArray<NSString *> *namespaces;

/**
 * Information about the sender application that is the counterpart to the receiver application,
 * if any.
 */
@property(nonatomic, copy, readonly) id<KPGSenderApplicationInfo> senderApplicationInfo;

/**
 * The identifier (app ID) of the sender application that is the counterpart to the receiver
 * application, if any.
 */
- (NSString *)senderAppIdentifier;

/**
 * The launch URL (URL scheme) for the sender application that is the counterpart to the receiver
 * application, if any.
 */
- (NSURL *)senderAppLaunchURL;

@end


typedef NS_ENUM(NSInteger, KPGMediaMetadataType) {
    /**  A media type representing generic media content. */
    KPGMediaMetadataTypeGeneric = 0,
    /** A media type representing a movie. */
    KPGMediaMetadataTypeMovie = 1,
    /** A media type representing an TV show. */
    KPGMediaMetadataTypeTVShow = 2,
    /** A media type representing a music track. */
    KPGMediaMetadataTypeMusicTrack = 3,
    /** A media type representing a photo. */
    KPGMediaMetadataTypePhoto = 4,
    /** The smallest media type value that can be assigned for application-defined media types. */
    KPGMediaMetadataTypeUser = 100,
};

@protocol KPGMediaMetadata <NSObject, NSCopying>

/**
 * The metadata type.
 */
@property(nonatomic, assign, readonly) KPGMediaMetadataType metadataType;

/**
 * Initializes a new, empty, MediaMetadata with the given media type.
 * Designated initializer.
 *
 * @param metadataType The media type; one of the @ref KPGMediaMetadataType constants, or a
 * value greater than or equal to @ref KPGMediaMetadataTypeUser for custom media types.
 */
- (instancetype)initWithMetadataType:(KPGMediaMetadataType)metadataType;

/**
 * Initialize with the generic metadata type.
 */
- (instancetype)init;

/**
 * The metadata type.
 */
- (KPGMediaMetadataType)metadataType;

/**
 * Gets the list of images.
 */
- (NSArray *)images;

/**
 * Removes all the current images.
 */
- (void)removeAllMediaImages;

/**
 * Adds an image to the list of images.
 *
 * @param image The image to add.
 */
- (void)addImage:(id<KPGImage>)image;

/**
 * Tests if the object contains a field with the given key.
 *
 * @param key The key.
 * @return <code>YES</code> if the field exists, <code>NO</code> otherwise.
 */
- (BOOL)containsKey:(NSString *)key;

/**
 * Returns a set of keys for all fields that are present in the object.
 */
- (NSArray<NSString *> *)allKeys;

/**
 * Reads the value of a field.
 *
 * @param key The key for the field.
 * @return The value of the field, or <code>nil</code> if the field has not been set.
 */
- (id)objectForKey:(NSString *)key;

/**
 * Stores a value in a string field.
 *
 * @param value The new value for the field.
 * @param key The key for the field.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not a string
 * field.
 */
- (void)setString:(NSString *)value forKey:(NSString *)key;

/**
 * Reads the value of a string field.
 *
 * @param key The key for the field.
 * @return The value of the field, or <code>nil</code> if the field has not been set.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not a string
 * field.
 */
- (NSString *)stringForKey:(NSString *)key;

/**
 * Stores a value in an integer field.
 *
 * @param value The new value for the field.
 * @param key The key for the field.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not an integer
 * field.
 */
- (void)setInteger:(NSInteger)value forKey:(NSString *)key;

/**
 * Reads the value of an integer field.
 *
 * @param key The key for the field.
 * @return The value of the field, or 0 if the field has not been set.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not an integer
 * field.
 */
- (NSInteger)integerForKey:(NSString *)key;

/**
 * Reads the value of an integer field.
 *
 * @param key The key for the field.
 * @param defaultValue The value to return if the field has not been set.
 * @return The value of the field, or the given default value if the field has not been set.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not an integer
 * field.
 */
- (NSInteger)integerForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;

/**
 * Stores a value in a <b>double</b> field.
 *
 * @param value The new value for the field.
 * @param key The key for the field.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not a
 * <b>double</b> field.
 */
- (void)setDouble:(double)value forKey:(NSString *)key;

/**
 * Reads the value of a <b>double</b> field.
 *
 * @param key The key for the field.
 * @return The value of the field, or 0 if the field has not been set.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not a
 * <b>double</b> field.
 */
- (double)doubleForKey:(NSString *)key;

/**
 * Reads the value of a <b>double</b> field.
 *
 * @param defaultValue The value to return if the field has not been set.
 * @param key The key for the field.
 * @return The value of the field, or the given default value if the field has not been set.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not a
 * <b>double</b> field.
 */
- (double)doubleForKey:(NSString *)key defaultValue:(double)defaultValue;

/**
 * Stores a value in a date field as a restricted ISO-8601 representation of the date.
 *
 * @param date The new value for the field.
 * @param key The key for the field.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not a date
 * field.
 */
- (void)setDate:(NSDate *)date forKey:(NSString *)key;

/**
 * Reads the value of a date field from the restricted ISO-8601 representation of the date.
 *
 * @param key The field name.
 * @return The date, or <code>nil</code> if this field has not been set.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not a date
 * field.
 */
- (NSDate *)dateForKey:(NSString *)key;

/**
 * Reads the value of a date field, as a string.
 *
 * @param key The field name.
 * @return The date as a string containing the restricted ISO-8601 representation of the date, or
 * <code>nil</code> if this field has not been set.
 * @throw NSInvalidArgumentException if the key refers to a predefined field which is not a date
 * field.
 */
- (NSString *)dateAsStringForKey:(NSString *)key;

@end

/**
 * A class representing an ad break.
 *
 * @since 3.1
 */
@protocol KPGAdBreakInfo <NSObject>

/* The playback position, in seconds, at which this ad will start playing. */
@property(nonatomic, assign, readonly) NSTimeInterval playbackPosition;

/**
 * Designated initializer. Constructs a new KPGAdBreakInfo.
 * @param playbackPosition The playback position in seconds for this ad break.
 */
- (instancetype)initWithPlaybackPosition:(NSTimeInterval)playbackPosition;

@end

/**
 * @file KPGMediaTrack.h
 * KPGMediaTrackType and KPGMediaTextTrackSubtype enums.
 */
/**
 * @enum KPGMediaTrackType
 * Media track types.
 */
typedef NS_ENUM(NSInteger, KPGMediaTrackType) {
    /** Unknown track type. */
    KPGMediaTrackTypeUnknown = 0,
    /** Text. */
    KPGMediaTrackTypeText = 1,
    /** Audio. */
    KPGMediaTrackTypeAudio = 2,
    /** Video. */
    KPGMediaTrackTypeVideo = 3,
};

/**
 * @enum KPGMediaTextTrackSubtype
 * Media text track subtypes.
 */
typedef NS_ENUM(NSInteger, KPGMediaTextTrackSubtype) {
    /** Unknown text track subtype. */
    KPGMediaTextTrackSubtypeUnknown = 0,
    /** Subtitles. */
    KPGMediaTextTrackSubtypeSubtitles = 1,
    /** Captions. */
    KPGMediaTextTrackSubtypeCaptions = 3,
    /** Descriptions. */
    KPGMediaTextTrackSubtypeDescriptions = 4,
    /** Chapters. */
    KPGMediaTextTrackSubtypeChapters = 5,
    /** Metadata. */
    KPGMediaTextTrackSubtypeMetadata = 6,
};

/**
 * A class representing a media track. Instances of this object are immutable.
 */

@protocol KPGMediaTrack <NSObject, NSCopying, NSCoding>

/**
 * Designated initializer. Constructs a new KPGMediaTrack with the given property values.
 */
- (instancetype)initWithIdentifier:(NSInteger)identifier
                 contentIdentifier:(NSString *)contentIdentifier
                       contentType:(NSString *)contentType
                              type:(KPGMediaTrackType)type
                       textSubtype:(KPGMediaTextTrackSubtype)textSubtype
                              name:(NSString *)name
                      languageCode:(NSString *)languageCode
                        customData:(id)customData;

/** The track's unique numeric identifier. */
@property(nonatomic, assign, readonly) NSInteger identifier;

/** The track's content identifier, which may be <code>nil</code>. */
@property(nonatomic, copy, readonly) NSString *contentIdentifier;

/** The track's content (MIME) type. */
@property(nonatomic, copy, readonly) NSString *contentType;

/** The track's type. */
@property(nonatomic, assign, readonly) KPGMediaTrackType type;

/** The text track's subtype; applies only to text tracks. */
@property(nonatomic, assign, readonly) KPGMediaTextTrackSubtype textSubtype;

/** The track's name, which may be <code>nil</code>. */
@property(nonatomic, copy, readonly) NSString *name;

/** The track's RFC 1766 language code, which may be <code>nil</code>. */
@property(nonatomic, copy, readonly) NSString *languageCode;

/**
 * The custom data, if any. Must either be an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 */
@property(nonatomic, strong, readonly) id customData;

@end

@protocol KPGColor <NSObject, NSCoding, NSCopying>

/** The red intensity of the color; a value in the range [0.0, 1.0]. */
@property(nonatomic, readonly) CGFloat red;
/** The green intensity of the color; a value in the range [0.0, 1.0]. */
@property(nonatomic, readonly) CGFloat green;
/** The blue intensity of the color; a value in the range [0.0, 1.0]. */
@property(nonatomic, readonly) CGFloat blue;
/** The alpha (transparency) of the color; a value in the range [0.0, 1.0]. */
@property(nonatomic, readonly) CGFloat alpha;

/**
 * Designated initializer. Constructs a KPGColor object with the given red, green, blue, and alpha
 * values. All color components are in the range [0.0, 1.0].
 */
- (instancetype)initWithRed:(CGFloat)red
                      green:(CGFloat)green
                       blue:(CGFloat)blue
                      alpha:(CGFloat)alpha;

/**
 * Constructs a KPGColor object with the given red, green, blue values and an alpha value of 1.0
 * (full opacity). All color components are in the range [0.0, 1.0].
 */
- (instancetype)initWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;

#if TARGET_OS_IPHONE

/**
 * Constructs a KPGColor object from a UIColor.
 */
- (instancetype)initWithUIColor:(UIColor *)color;

#else

/**
 * Constructs a KPGColor object from an NSColor.
 */
- (instancetype)initWithNSColor:(NSColor *)color;

#endif  // TARGET_OS_IPHONE

/**
 * Constructs a KPGColor object from a CGColor.
 */
- (instancetype)initWithCGColor:(CGColorRef)color;

/**
 * Constructs a KPGColor object from a CSS string representation in the form "#RRGGBBAA".
 */
- (instancetype)initWithCSSString:(NSString *)CSSString;

/**
 * Returns a CSS string representation of the color, in the form "#RRGGBBAA".
 */
- (NSString *)CSSString;

/** The color black. */
+ (id<KPGColor>)black;
/** The color red. */
+ (id<KPGColor>)red;
/** The color green. */
+ (id<KPGColor>)green;
/** The color blue. */
+ (id<KPGColor>)blue;
/** The color cyan. */
+ (id<KPGColor>)cyan;
/** The color magenta. */
+ (id<KPGColor>)magenta;
/** The color yellow. */
+ (id<KPGColor>)yellow;
/** The color white. */
+ (id<KPGColor>)white;

@end

/**
 * @enum KPGMediaTextTrackStyleEdgeType
 * Closed caption text edge types (font effects).
 */
typedef NS_ENUM(NSInteger, KPGMediaTextTrackStyleEdgeType) {
    /** Unknown edge type. */
    KPGMediaTextTrackStyleEdgeTypeUnknown = -1,
    /** None. */
    KPGMediaTextTrackStyleEdgeTypeNone = 0,
    /** Outline. */
    KPGMediaTextTrackStyleEdgeTypeOutline = 1,
    /** Drop shadow. */
    KPGMediaTextTrackStyleEdgeTypeDropShadow = 2,
    /** Raised. */
    KPGMediaTextTrackStyleEdgeTypeRaised = 3,
    /** Depressed. */
    KPGMediaTextTrackStyleEdgeTypeDepressed = 4,
};

/**
 * @enum KPGMediaTextTrackStyleWindowType
 * Closed caption window types.
 */
typedef NS_ENUM(NSInteger, KPGMediaTextTrackStyleWindowType) {
    /** Unknown window type. */
    KPGMediaTextTrackStyleWindowTypeUnknown = -1,
    /** None. */
    KPGMediaTextTrackStyleWindowTypeNone = 0,
    /** Normal. */
    KPGMediaTextTrackStyleWindowTypeNormal = 1,
    /** Rounded corners. */
    KPGMediaTextTrackStyleWindowTypeRoundedCorners = 2,
};

/**
 * @enum KPGMediaTextTrackStyleFontGenericFamily
 * Closed caption text generic font families.
 */
typedef NS_ENUM(NSInteger, KPGMediaTextTrackStyleFontGenericFamily) {
    /** Unknown font family. */
    KPGMediaTextTrackStyleFontGenericFamilyUnknown = -1,
    /** None. */
    KPGMediaTextTrackStyleFontGenericFamilyNone = 0,
    /** Sans serif. */
    KPGMediaTextTrackStyleFontGenericFamilySansSerif = 1,
    /** Monospaced sans serif. */
    KPGMediaTextTrackStyleFontGenericFamilyMonospacedSansSerif = 2,
    /** Serif. */
    KPGMediaTextTrackStyleFontGenericFamilySerif = 3,
    /** Monospaced serif. */
    KPGMediaTextTrackStyleFontGenericFamilyMonospacedSerif = 4,
    /** Casual. */
    KPGMediaTextTrackStyleFontGenericFamilyCasual = 5,
    /** Cursive. */
    KPGMediaTextTrackStyleFontGenericFamilyCursive = 6,
    /** Small Capitals. */
    KPGMediaTextTrackStyleFontGenericFamilySmallCapitals = 7,
};

/**
 * @enum KPGMediaTextTrackStyleFontStyle
 * Closed caption text font styles.
 */
typedef NS_ENUM(NSInteger, KPGMediaTextTrackStyleFontStyle) {
    /** Unknown font style. */
    KPGMediaTextTrackStyleFontStyleUnknown = -1,
    /** Normal. */
    KPGMediaTextTrackStyleFontStyleNormal = 0,
    /** Bold. */
    KPGMediaTextTrackStyleFontStyleBold = 1,
    /** Italic. */
    KPGMediaTextTrackStyleFontStyleItalic = 2,
    /** Bold italic. */
    KPGMediaTextTrackStyleFontStyleBoldItalic = 3,
};
/**
 * A class representing a style for a text media track.
 */
@protocol KPGMediaTextTrackStyle  <NSObject>

/**
 * Designated initializer. All properties are mutable and so can be supplied after construction.
 */
- (instancetype)init;

/**
 * Creates an instance with default values based on the system's closed captioning settings. This
 * method will return nil on systems older than iOS 7.
 */
+ (instancetype)createDefault;

/** The font scaling factor for the text. */
@property(nonatomic) CGFloat fontScale;

/** The foreground color. */
@property(nonatomic, copy, readwrite) id<KPGColor> foregroundColor;

/** The background color. */
@property(nonatomic, copy, readwrite) id<KPGColor> backgroundColor;

/** The edge type. */
@property(nonatomic, assign, readwrite) KPGMediaTextTrackStyleEdgeType edgeType;

/** The edge color. */
@property(nonatomic, copy, readwrite) id<KPGColor> edgeColor;

/** The window type. */
@property(nonatomic, assign, readwrite) KPGMediaTextTrackStyleWindowType windowType;

/** The window color. */
@property(nonatomic, copy, readwrite) id<KPGColor> windowColor;

/** Rounded corner radius absolute value in pixels. */
@property(nonatomic, assign, readwrite) CGFloat windowRoundedCornerRadius;

/** The font family; if the font is not available, the generic font family will be used. **/
@property(nonatomic, copy, readwrite) NSString *fontFamily;

/** The generic font family. */
@property(nonatomic, assign, readwrite) KPGMediaTextTrackStyleFontGenericFamily fontGenericFamily;

/** The font style. */
@property(nonatomic, assign, readwrite) KPGMediaTextTrackStyleFontStyle fontStyle;

/** The custom data, if any. */
@property(nonatomic, strong, readwrite) id customData;

@end

/**
 * @enum KPGMediaStreamType
 * Enum defining the media stream type.
 */
typedef NS_ENUM(NSInteger, KPGMediaStreamType) {
    /** A stream type of "none". */
    KPGMediaStreamTypeNone = 0,
    /** A buffered stream type. */
    KPGMediaStreamTypeBuffered = 1,
    /** A live stream type. */
    KPGMediaStreamTypeLive = 2,
    /** An unknown stream type. */
    KPGMediaStreamTypeUnknown = 99,
};

/**
 * A class that aggregates information about a media item.
 */
@protocol KPGMediaInformation <NSObject, NSCopying>

/**
 * The content ID for this stream.
 */
@property(nonatomic, copy, readonly) NSString *contentID;

/**
 * The stream type.
 */
@property(nonatomic, readonly) KPGMediaStreamType streamType;

/**
 * The content (MIME) type.
 */
@property(nonatomic, copy, readonly) NSString *contentType;

/**
 * The media item metadata.
 */
@property(nonatomic, strong, readonly) id<KPGMediaMetadata> metadata;

/**
 * The list of ad breaks in this content.
 */
@property(nonatomic, copy, readonly) NSArray<id<KPGAdBreakInfo>> *adBreaks;

/**
 * The length of the stream, in seconds, or <code>INFINITY</code> if it is a live stream.
 */
@property(nonatomic, readonly) NSTimeInterval streamDuration;

/**
 * The media tracks for this stream.
 */
@property(nonatomic, copy, readonly) NSArray<id<KPGMediaTrack>> *mediaTracks;

/**
 * The text track style for this stream.
 */
@property(nonatomic, copy, readonly) id<KPGMediaTextTrackStyle> textTrackStyle;

/**
 * The custom data, if any.
 */
@property(nonatomic, strong, readonly) id customData;

/**
 * Designated initializer.
 *
 * @param contentID The content ID.
 * @param streamType The stream type.
 * @param contentType The content (MIME) type.
 * @param metadata The media item metadata.
 * @param streamDuration The stream duration.
 * @param mediaTracks The media tracks, if any, otherwise <code>nil</code>.
 * @param textTrackStyle The text track style, if any, otherwise <code>nil</code>.
 * @param customData The custom application-specific data. Must either be an object that can be
 * serialized to JSON using <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or
 * <code>nil</code>.
 */
- (instancetype)initWithContentID:(NSString *)contentID
                       streamType:(KPGMediaStreamType)streamType
                      contentType:(NSString *)contentType
                         metadata:(id<KPGMediaMetadata>)metadata
                   streamDuration:(NSTimeInterval)streamDuration
                      mediaTracks:(NSArray<id<KPGMediaTrack>> *)mediaTracks
                   textTrackStyle:(id<KPGMediaTextTrackStyle>)textTrackStyle
                       customData:(id)customData;

/**
 * Legacy initializer; does not include media tracks or text track style.
 *
 * @param contentID The content ID.
 * @param streamType The stream type.
 * @param contentType The content (MIME) type.
 * @param metadata The media item metadata.
 * @param streamDuration The stream duration.
 * @param customData Custom application-specific data. Must either be an object that can be
 * serialized to JSON using <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or
 * <code>nil</code>.
 *
 * @deprecated Use the designated initializer.
 */
- (instancetype)initWithContentID:(NSString *)contentID
                       streamType:(KPGMediaStreamType)streamType
                      contentType:(NSString *)contentType
                         metadata:(id<KPGMediaMetadata>)metadata
                   streamDuration:(NSTimeInterval)streamDuration
                       customData:(id)customData;

/**
 * Searches for a media track with the given track ID.
 *
 * @param trackID The media track ID.
 * @return The matching KPGMediaTrack object, or <code>nil</code> if there is no media track
 * with the given ID.
 */
- (id<KPGMediaTrack>)mediaTrackWithID:(NSInteger)trackID;

@end

@protocol KPGMediaQueueItemBuilder;

/**
 * A class representing a media queue item. Instances of this object are immutable.
 *
 * This class is used in two-way communication between a sender application and a receiver
 * application. The sender constructs them to load or insert a list of media items on the receiver
 * application. The @ref KPGMediaStatus from the receiver also contains the list of items
 * represented as instances of this class.
 *
 * Once loaded, the receiver will assign a unique item ID to each KPGMediaQueueItem, even if the
 * same media gets loaded multiple times.
 */

@protocol KPGMediaQueueItem <NSObject, NSCopying>

/** The media information associated with this item. */
@property(nonatomic, strong, readonly) id<KPGMediaInformation> mediaInformation;

/** The item ID, or @ref kKPGMediaQueueInvalidItemID if one has not yet been assigned. */
@property(nonatomic, readonly) NSUInteger itemID;

/**
 * Whether the item should automatically start playback when it becomes the current item in the
 * queue. If <code>NO</code>, the queue will pause when it reaches this item. The default value is
 * <code>YES</code>.
 */
@property(nonatomic, readonly) BOOL autoplay;

/**
 * The start time of the item, in seconds. The default value is @ref kKPGInvalidTimeInterval,
 * indicating that no start time has been set.
 */
@property(nonatomic, readonly) NSTimeInterval startTime;

/**
 * The playback duration for the item, in seconds, or <code>INFINITY</code> if the stream's actual
 * duration should be used.
 */
@property(nonatomic, readonly) NSTimeInterval playbackDuration;

/**
 * How long before the previous item ends, in seconds, before the receiver should start
 * preloading this item. The default value is @ref kKPGInvalidTimeInterval, indicating that no
 * preload time has been set.
 */
@property(nonatomic, readonly) NSTimeInterval preloadTime;

/** The active track IDs for this item. */
@property(nonatomic, strong, readonly) NSArray<NSNumber *> *activeTrackIDs;

/** The custom data associated with this item, if any. */
@property(nonatomic, strong, readonly) id customData;

/**
 * Constructs a new KPGMediaQueueItem with the given attributes. See the documentation of the
 * corresponding properties for more information.
 *
 * @param mediaInformation The media information for the item.
 * @param autoplay The autoplay state for this item.
 * @param startTime The start time of the item, in seconds. May be
 * @ref kKPGInvalidTimeInterval if this item refers to a live stream or if the default start time
 * should be used.
 * @param preloadTime The preload time for the item, in seconds. May be @ref kKPGInvalidTimeInterval
 * to indicate no preload time.
 * @param activeTrackIDs The active track IDs for the item. May be <code>nil</code>.
 * @param customData Any custom data to associate with the item. May be <code>nil</code>.
 */
- (instancetype)initWithMediaInformation:(id<KPGMediaInformation> )mediaInformation
                                autoplay:(BOOL)autoplay
                               startTime:(NSTimeInterval)startTime
                             preloadTime:(NSTimeInterval)preloadTime
                          activeTrackIDs:(NSArray<NSNumber *> *)activeTrackIDs
                              customData:(id)customData;

/**
 * Designated initializer. Constructs a new KPGMediaQueueItem with the given attributes. See the
 * documentation of the corresponding properties for more information.
 *
 * @param mediaInformation The media information for the item.
 * @param autoplay The autoplay state for this item.
 * @param startTime The start time of the item, in seconds. May be @ref kKPGInvalidTimeInterval if
 * this item refers to a live stream or if the default start time should be used.
 * @param playbackDuration The playback duration of the item, in seconds. May be
 * @ref kKPGInvalidTimeInterval to indicate no preload time.
 * @param preloadTime The preload time for the item, in seconds.
 * @param activeTrackIDs The active track IDs for the item. May be <code>nil</code>.
 * @param customData Any custom data to associate with the item. May be <code>nil</code>.
 */
- (instancetype)initWithMediaInformation:(id<KPGMediaInformation>)mediaInformation
                                autoplay:(BOOL)autoplay
                               startTime:(NSTimeInterval)startTime
                        playbackDuration:(NSTimeInterval)playbackDuration
                             preloadTime:(NSTimeInterval)preloadTime
                          activeTrackIDs:(NSArray<NSNumber *> *)activeTrackIDs
                              customData:(id)customData /*NS_DESIGNATED_INITIALIZER*/;

/**
 * Clears (unassigns) the item ID. Should be called in order to reuse an existing instance, for
 * example, to add it back to a queue.
 */
- (void)clearItemID;

/**
 * Returns a copy of this KPGMediaQueueItem that has been modified by the given block.
 *
 * @param block A block that receives a KPGMediaQueueItemBuilder which can be used to modify
 * attributes of the copy. It is not necessary to call the builder's KPGMediaQueueItemBuilder::build
 * method within the block, as this method will do that automatically when the block completes.
 * @return A modified copy of this item.
 */
- (instancetype)mediaQueueItemModifiedWithBlock:(void (^)(id<KPGMediaQueueItemBuilder> builder))block;

@end

/**
 * A builder object for constructing new or derived KPGMediaQueueItem instances. The builder may be
 * used to derive a KPGMediaQueueItem from an existing one:
 *
 * @code
 * KPGMediaQueueItemBuilder *builder =
 *     [[KPGMediaQueueItemBuilder alloc] initWithMediaQueueItem:originalItem];
 * builder.startTime = 10; // Change the start time.
 * builder.autoplay = NO; // Change the autoplay flag.
 * KPGMediaQueueItem *derivedItem = [builder build];
 * @endcode
 *
 * It can also be used to construct a new KPGMediaQueueItem from scratch:
 *
 * @code
 * KPGMediaQueueItemBuilder *builder = [[KPGMediaQueueItemBuilder alloc] init];
 * builder.mediaInformation = ...;
 * builder.autoplay = ...;
 * // Set all other desired propreties...
 * KPGMediaQueueItem *newItem = [builder build];
 * @endcode
 */

@protocol KPGMediaQueueItemBuilder <NSObject>

/** The media information associated with this item. */
@property(nonatomic, copy, readwrite) id<KPGMediaInformation> mediaInformation;

/**
 * Whether the item should automatically start playback when it becomes the current item in the
 * queue. If <code>NO</code>, the queue will pause when it reaches this item. The default value is
 * <code>YES</code>.
 */
@property(nonatomic, assign, readwrite) BOOL autoplay;

/**
 * The start time of the item, in seconds. The default value is @ref kKPGInvalidTimeInterval,
 * indicating that a start time does not apply (for example, for a live stream) or that the default
 * start time should be used.
 */
@property(nonatomic, assign, readwrite) NSTimeInterval startTime;

/**
 * The playback duration for the item, in seconds, or <code>INFINITY</code> if the stream's actual
 * duration should be used.
 */
@property(nonatomic, assign, readwrite) NSTimeInterval playbackDuration;

/**
 * How long before the previous item ends, in seconds, before the receiver should start preloading
 * this item. The default value is @ref kKPGInvalidTimeInterval, indicating no preload time.
 */
@property(nonatomic, assign, readwrite) NSTimeInterval preloadTime;

/** The active track IDs for this item. */
@property(nonatomic, copy, readwrite) NSArray<NSNumber *> *activeTrackIDs;

/** The custom data associated with this item, if any. */
@property(nonatomic, copy, readwrite) id customData;

/**
 * Constructs a new KPGMediaQueueItemBuilder with attributes initialized to default values.
 */
- (instancetype)init;

/**
 * Constructs a new KPGMediaQueueItemBuilder with attributes copied from the given
 * KPGMediaQueueItem, including the item ID.
 *
 * @param item The item to copy.
 */
- (instancetype)initWithMediaQueueItem:(id<KPGMediaQueueItem>)item;

/**
 * Builds a KPGMediaQueueItem using the builder's current attributes.
 */
- (id<KPGMediaQueueItem>)build;

@end


/**
 * @enum KPGMediaPlayerState
 * Media player states.
 */
typedef NS_ENUM(NSInteger, KPGMediaPlayerState) {
    /** Constant indicating unknown player state. */
    KPGMediaPlayerStateUnknown = 0,
    /** Constant indicating that the media player is idle. */
    KPGMediaPlayerStateIdle = 1,
    /** Constant indicating that the media player is playing. */
    KPGMediaPlayerStatePlaying = 2,
    /** Constant indicating that the media player is paused. */
    KPGMediaPlayerStatePaused = 3,
    /** Constant indicating that the media player is buffering. */
    KPGMediaPlayerStateBuffering = 4,
};

/**
 * @enum KPGMediaControlChannelResumeState
 * Enum defining the media control channel resume state.
 */
typedef NS_ENUM(NSInteger, KPGMediaControlChannelResumeState) {
    /** A resume state indicating that the player state should be left unchanged. */
    KPGMediaControlChannelResumeStateUnchanged = 0,
    
    /**
     * A resume state indicating that the player should be playing, regardless of its current
     * state.
     */
    KPGMediaControlChannelResumeStatePlay = 1,
    
    /**
     * A resume state indicating that the player should be paused, regardless of its current
     * state.
     */
    KPGMediaControlChannelResumeStatePause = 2,
};

/**
 * @enum KPGMediaRepeatMode
 * Enum defining the media control channel queue playback repeat modes.
 */
typedef NS_ENUM(NSInteger, KPGMediaRepeatMode) {
    /** A repeat mode indicating that the repeat mode should be left unchanged. */
    KPGMediaRepeatModeUnchanged = 0,
    
    /** A repeat mode indicating no repeat. */
    KPGMediaRepeatModeOff = 1,
    
    /** A repeat mode indicating that a single queue item should be played repeatedly. */
    KPGMediaRepeatModeSingle = 2,
    
    /** A repeat mode indicating that the entire queue should be played repeatedly. */
    KPGMediaRepeatModeAll = 3,
    
    /**
     * A repeat mode indicating that the entire queue should be played repeatedly. The order of the
     * items will be randomly shuffled once the last item in the queue finishes. The queue will
     * continue to play starting from the first item of the shuffled items.
     */
    KPGMediaRepeatModeAllAndShuffle = 4,
};


/**
 * @enum KPGMediaPlayerIdleReason
 * Media player idle reasons.
 */
typedef NS_ENUM(NSInteger, KPGMediaPlayerIdleReason) {
    /** Constant indicating that the player currently has no idle reason. */
    KPGMediaPlayerIdleReasonNone = 0,
    
    /** Constant indicating that the player is idle because playback has finished. */
    KPGMediaPlayerIdleReasonFinished = 1,
    
    /**
     * Constant indicating that the player is idle because playback has been cancelled in
     * response to a STOP command.
     */
    KPGMediaPlayerIdleReasonCancelled = 2,
    
    /**
     * Constant indicating that the player is idle because playback has been interrupted by
     * a LOAD command.
     */
    KPGMediaPlayerIdleReasonInterrupted = 3,
    
    /** Constant indicating that the player is idle because a playback error has occurred. */
    KPGMediaPlayerIdleReasonError = 4,
};

/**
 * A class that holds status information about some media.
 */

@protocol KPGMediaStatus <NSObject, NSCopying>

/**
 * The media session ID for this item.
 */
@property(nonatomic, assign, readonly) NSInteger mediaSessionID;

/**
 * The current player state.
 */
@property(nonatomic, assign, readonly) KPGMediaPlayerState playerState;

/**
 * Indicates whether the receiver is currently playing an ad.
 */
@property(nonatomic, assign, readonly) BOOL playingAd;

/**
 * The current idle reason. This value is only meaningful if the player state is
 * KPGMediaPlayerStateIdle.
 */
@property(nonatomic, assign, readonly) KPGMediaPlayerIdleReason idleReason;

/**
 * Gets the current stream playback rate. This will be negative if the stream is seeking
 * backwards, 0 if the stream is paused, 1 if the stream is playing normally, and some other
 * postive value if the stream is seeking forwards.
 */
@property(nonatomic, assign, readonly) float playbackRate;

/**
 * The KPGMediaInformation for this item.
 */
@property(nonatomic, strong, readonly) id<KPGMediaInformation> mediaInformation;

/**
 * The current stream position, as an NSTimeInterval from the start of the stream.
 */
@property(nonatomic, assign, readonly) NSTimeInterval streamPosition;

/**
 * The stream's volume.
 */
@property(nonatomic, assign, readonly) float volume;

/**
 * The stream's mute state.
 */
@property(nonatomic, assign, readonly) BOOL isMuted;

/**
 * The current queue repeat mode.
 */
@property(nonatomic, assign, readonly) KPGMediaRepeatMode queueRepeatMode;

/**
 * The ID of the current queue item, if any.
 */
@property(nonatomic, assign, readonly) NSUInteger currentItemID;

/**
 * Whether there is a current item in the queue.
 */
@property(nonatomic, assign, readonly) BOOL queueHasCurrentItem;

/**
 * The current queue item, if any.
 */
@property(nonatomic, assign, readonly) id<KPGMediaQueueItem> currentQueueItem;

/**
 * Checks if there is an item after the currently playing item in the queue.
 */
- (BOOL)queueHasNextItem;

/**
 * The next queue item, if any.
 */
@property(nonatomic, assign, readonly) id<KPGMediaQueueItem> nextQueueItem;

/**
 * Whether there is an item before the currently playing item in the queue.
 */
@property(nonatomic, assign, readonly) BOOL queueHasPreviousItem;

/**
 * Whether there is an item being preloaded in the queue.
 */
@property(nonatomic, assign, readonly) BOOL queueHasLoadingItem;

/**
 * The ID of the item that is currently preloaded, if any.
 */
@property(nonatomic, assign, readonly) NSUInteger preloadedItemID;

/**
 * The ID of the item that is currently loading, if any.
 */
@property(nonatomic, assign, readonly) NSUInteger loadingItemID;

/**
 * The list of active track IDs.
 */
@property(nonatomic, strong, readonly) NSArray<NSNumber *> *activeTrackIDs;

/**
 * Any custom data that is associated with the media item.
 */
@property(nonatomic, strong, readonly) id customData;

/**
 * Designated initializer.
 *
 * @param mediaSessionID The media session ID.
 * @param mediaInformation The media information.
 */
- (instancetype)initWithSessionID:(NSInteger)mediaSessionID
                 mediaInformation:(id<KPGMediaInformation>)mediaInformation;

/**
 * Checks if the stream supports a given control command.
 */
- (BOOL)isMediaCommandSupported:(NSInteger)command;

/**
 * Returns the number of items in the playback queue.
 */
- (NSUInteger)queueItemCount;

/**
 * Returns the item at the specified index in the playback queue.
 */
- (id<KPGMediaQueueItem>)queueItemAtIndex:(NSUInteger)index;

/**
 * Returns the item with the given item ID in the playback queue.
 */
- (id<KPGMediaQueueItem>)queueItemWithItemID:(NSUInteger)itemID;

/**
 * Returns the index of the item with the given item ID in the playback queue, or -1 if there is
 * no such item in the queue.
 */
- (NSInteger)queueIndexForItemID:(NSUInteger)itemID;

@end

typedef KPGMediaControlChannelResumeState KPGMediaResumeState;

@protocol KPGRemoteMediaClientListener;
@protocol KPGRemoteMediaClientAdInfoParserDelegate;

@protocol KPGRequest;

/**
 * A class for controlling media playback on a Cast receiver. This class provides the same
 * functionality as the deprecated KPGMediaControlChannel, which it wraps, but with a more
 * convenient API. The main differences are:
 * <ul>
 * <li>Each request is represented by a KPGRequest object which can be tracked with a dedicated
 * delegate.
 * <li>The KPGRemoteMediaClient supports multiple listeners rather than a single delegate.
 * </ul>
 *
 * @since 3.0
 */

@protocol KPGRemoteMediaClient  <NSObject>

/** A flag that indicates whether this object is connected to a session. */
@property(nonatomic, assign, readonly) BOOL connected;

/** The current media status, as reported by the media control channel. */
@property(nonatomic, strong, readonly) id<KPGMediaStatus> mediaStatus;

/**
 * The amount of time that has passed since the last media status update was received. If a
 * status request is currently in progress, this will be 0.
 */
@property(nonatomic, assign, readonly) NSTimeInterval timeSinceLastMediaStatusUpdate;

/**
 * Adds a listener to this object's list of listeners.
 *
 * @param listener The listener to add.
 */
- (void)addListener:(id<KPGRemoteMediaClientListener>)listener;

/**
 * Removes a listener from this object's list of listeners.
 *
 * @param listener The listener to remove.
 */
- (void)removeListener:(id<KPGRemoteMediaClientListener>)listener;

/**
 * A delegate capable of extracting ad break information from the custom data in a KPGMediaStatus
 * object.
 */
@property(nonatomic, weak, readwrite) id<KPGRemoteMediaClientAdInfoParserDelegate>
adInfoParserDelegate;

/**
 * Loads and starts playback of a new media item.
 *
 * @param mediaInfo An object describing the media item to load.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)loadMedia:(id<KPGMediaInformation>)mediaInfo;

/**
 * Loads and optionally starts playback of a new media item.
 *
 * @param mediaInfo An object describing the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)loadMedia:(id<KPGMediaInformation>)mediaInfo autoplay:(BOOL)autoplay;

/**
 * Loads and optionally starts playback of a new media item.
 *
 * @param mediaInfo An object describing the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @param playPosition The initial playback position.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)loadMedia:(id<KPGMediaInformation>)mediaInfo
                 autoplay:(BOOL)autoplay
             playPosition:(NSTimeInterval)playPosition;

/**
 * Loads and optionally starts playback of a new media item.
 *
 * @param mediaInfo An object describing the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @param playPosition The initial playback position.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)loadMedia:(id<KPGMediaInformation>)mediaInfo
                 autoplay:(BOOL)autoplay
             playPosition:(NSTimeInterval)playPosition
               customData:(id)customData;

/**
 * Loads and optionally starts playback of a new media item.
 *
 * @param mediaInfo An object describing the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @param playPosition The initial playback position.
 * @param activeTrackIDs An array of integers specifying the active tracks.
 * May be <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)loadMedia:(id<KPGMediaInformation>)mediaInfo
                 autoplay:(BOOL)autoplay
             playPosition:(NSTimeInterval)playPosition
           activeTrackIDs:(NSArray<NSNumber *> *)activeTrackIDs;

/**
 * Loads and optionally starts playback of a new media item.
 *
 * @param mediaInfo An object describing the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @param playPosition The initial playback position.
 * @param activeTrackIDs An array of integers specifying the active tracks.
 * May be <code>nil</code>.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)loadMedia:(id<KPGMediaInformation>)mediaInfo
                 autoplay:(BOOL)autoplay
             playPosition:(NSTimeInterval)playPosition
           activeTrackIDs:(NSArray<NSNumber *> *)activeTrackIDs
               customData:(id)customData;

/**
 * Sets the active tracks. The request will fail if there is no current media status.
 *
 * @param activeTrackIDs An array of integers specifying the active tracks. May be empty or
 * <code>nil</code> to disable any currently active tracks.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)setActiveTrackIDs:(NSArray<NSNumber *> *)activeTrackIDs;

/**
 * Sets the text track style. The request will fail if there is no current media status.
 *
 * @param textTrackStyle The text track style. The style will not be changed if this is
 * <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)setTextTrackStyle:(id<KPGMediaTextTrackStyle>)textTrackStyle;

/**
 * Pauses playback of the current media item. The request will fail if there is no current media
 * status.
 *
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)pause;

/**
 * Pauses playback of the current media item. The request will fail if there is no current media
 * status.
 *
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)pauseWithCustomData:(id)customData;

/**
 * Stops playback of the current media item. If a queue is currently loaded, it will be removed. The
 * request will fail if there is no current media status.
 *
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)stop;

/**
 * Stops playback of the current media item. If a queue is currently loaded, it will be removed. The
 * request will fail if there is no current media status.
 *
 *
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)stopWithCustomData:(id)customData;

/**
 * Begins (or resumes) playback of the current media item. Playback always begins at the
 * beginning of the stream. The request will fail if there is no current media status.
 *
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)play;

/**
 * Begins (or resumes) playback of the current media item. Playback always begins at the
 * beginning of the stream. The request will fail if there is no current media status.
 *
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)playWithCustomData:(id)customData;

/**
 * Seeks to a new position within the current media item. The request will fail if there is no
 * current media status.
 *
 * @param position The new position from the beginning of the stream.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)seekToTimeInterval:(NSTimeInterval)position;

/**
 * Seeks to a new position within the current media item. The request will fail if there is no
 * current media status.
 *
 * @param position The new position interval from the beginning of the stream.
 * @param resumeState The action to take after the seek operation has finished.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)seekToTimeInterval:(NSTimeInterval)position
                       resumeState:(KPGMediaResumeState)resumeState;

/**
 * Seeks to a new position within the current media item. The request will fail if there is no
 * current media status.
 *
 * @param position The new position from the beginning of the stream.
 * @param resumeState The action to take after the seek operation has finished.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)seekToTimeInterval:(NSTimeInterval)position
                       resumeState:(KPGMediaResumeState)resumeState
                        customData:(id)customData;

/**
 * Loads and optionally starts playback of a new queue of media items.
 *
 * @param queueItems An array of KPGMediaQueueItem instances to load. Must not be <code>nil</code>
 * or empty.
 * @param startIndex The index of the item in the items array that should be played first.
 * @param repeatMode The repeat mode for playing the queue.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueLoadItems:(NSArray<id<KPGMediaQueueItem>> *)queueItems
                    startIndex:(NSUInteger)startIndex
                    repeatMode:(KPGMediaRepeatMode)repeatMode;

/**
 * Loads and optionally starts playback of a new queue of media items.
 *
 * @param queueItems An array of KPGMediaQueueItem instances to load. Must not be <code>nil</code>
 * or empty.
 * @param startIndex The index of the item in the items array that should be played first.
 * @param repeatMode The repeat mode for playing the queue.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueLoadItems:(NSArray<id<KPGMediaQueueItem>> *)queueItems
                    startIndex:(NSUInteger)startIndex
                    repeatMode:(KPGMediaRepeatMode)repeatMode
                    customData:(id)customData;

/**
 * Loads and optionally starts playback of a new queue of media items.
 *
 * @param queueItems An array of KPGMediaQueueItem instances to load. Must not be <code>nil</code>
 * or empty.
 * @param startIndex The index of the item in the items array that should be played first.
 * @param playPosition The initial playback position for the item when it is first played,
 * relative to the beginning of the stream. This value is ignored when the same item is played
 * again, for example when the queue repeats, or the item is later jumped to. In those cases the
 * item's startTime is used.
 * @param repeatMode The repeat mode for playing the queue.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueLoadItems:(NSArray<id<KPGMediaQueueItem>> *)queueItems
                    startIndex:(NSUInteger)startIndex
                  playPosition:(NSTimeInterval)playPosition
                    repeatMode:(KPGMediaRepeatMode)repeatMode
                    customData:(id)customData;

/**
 * Inserts a list of new media items into the queue.
 *
 * @param queueItems An array of KPGMediaQueueItem instances to insert. Must not be <code>nil</code>
 * or empty.
 * @param beforeItemID The ID of the item that will be located immediately after the inserted list.
 * If the value is @ref kKPGMediaQueueInvalidItemID, the inserted list will be appended to the end
 * of the queue.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueInsertItems:(NSArray<id<KPGMediaQueueItem>> *)queueItems
                beforeItemWithID:(NSUInteger)beforeItemID;

/**
 * Inserts a list of new media items into the queue.
 *
 * @param queueItems An array of KPGMediaQueueItem instances to insert. Must not be <code>nil</code>
 * or empty.
 * @param beforeItemID ID of the item that will be located immediately after the inserted list. If
 * the value is @ref kKPGMediaQueueInvalidItemID, the inserted list will be appended to the end of
 * the queue.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueInsertItems:(NSArray<id<KPGMediaQueueItem>> *)queueItems
                beforeItemWithID:(NSUInteger)beforeItemID
                      customData:(id)customData;

/**
 * A convenience method that inserts a single item into the queue.
 *
 * @param item The item to insert.
 * @param beforeItemID The ID of the item that will be located immediately after the inserted item.
 * If the value is @ref kKPGMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the inserted item will be appended to the end of the queue.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueInsertItem:(id<KPGMediaQueueItem>)item beforeItemWithID:(NSUInteger)beforeItemID;

/**
 * A convenience method that inserts a single item into the queue and makes it the current item.
 *
 * @param item The item to insert.
 * @param beforeItemID The ID of the item that will be located immediately after the inserted item.
 * If the value is @ref kKPGMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the inserted item will be appended to the end of the queue.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueInsertAndPlayItem:(id<KPGMediaQueueItem>)item
                      beforeItemWithID:(NSUInteger)beforeItemID;

/**
 * A convenience method that inserts a single item into the queue and makes it the current item.
 *
 * @param item The item to insert.
 * @param beforeItemID The ID of the item that will be located immediately after the inserted item.
 * If the value is @ref kKPGMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the inserted item will be appended to the end of the queue.
 * @param playPosition The initial playback position for the item when it is first played,
 * relative to the beginning of the stream. This value is ignored when the same item is played
 * again, for example when the queue repeats, or the item is later jumped to. In those cases the
 * item's startTime is used.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueInsertAndPlayItem:(id<KPGMediaQueueItem>)item
                      beforeItemWithID:(NSUInteger)beforeItemID
                          playPosition:(NSTimeInterval)playPosition
                            customData:(id)customData;

/**
 * Updates the queue.
 *
 * @param queueItems The list of updated items.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueUpdateItems:(NSArray<id<KPGMediaQueueItem>> *)queueItems;

/**
 * Updates the queue.
 *
 * @param queueItems The list of updated items.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueUpdateItems:(NSArray<id<KPGMediaQueueItem>> *)queueItems
                      customData:(id)customData;

/**
 * Removes a list of media items from the queue. If the queue becomes empty as a result, the current
 * media session will be terminated.
 *
 * @param itemIDs An array of media item IDs identifying the items to remove. Must not be
 * <code>nil</code> or empty.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueRemoveItemsWithIDs:(NSArray<NSNumber *> *)itemIDs;

/**
 * Removes a list of media items from the queue. If the queue becomes empty as a result, the current
 * media session will be terminated.
 *
 * @param itemIDs An array of media item IDs identifying the items to remove. Must not be
 * <code>nil</code> or empty.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueRemoveItemsWithIDs:(NSArray<NSNumber *> *)itemIDs
                             customData:(id)customData;

/**
 * A convenience method that removes a single item from the queue.
 *
 * @param itemID The ID of the item to remove.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueRemoveItemWithID:(NSUInteger)itemID;

/**
 * Reorders a list of media items in the queue.
 *
 * @param queueItemIDs An array of media item IDs identifying the items to reorder. Must not be
 * <code>nil</code> or empty.
 * @param beforeItemID ID of the item that will be located immediately after the reordered list. If
 * the value is @ref kKPGMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the reordered list will be appended at the end of the queue.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueReorderItemsWithIDs:(NSArray<NSNumber *> *)queueItemIDs
                  insertBeforeItemWithID:(NSUInteger)beforeItemID;

/**
 * Reorder a list of media items in the queue.
 *
 * @param queueItemIDs An array of media item IDs identifying the items to reorder. Must not be
 * <code>nil</code> or empty.
 * @param beforeItemID The ID of the item that will be located immediately after the reordered list.
 * If the value is @ref kKPGMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the reordered list will be moved to the end of the queue.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueReorderItemsWithIDs:(NSArray<NSNumber *> *)queueItemIDs
                  insertBeforeItemWithID:(NSUInteger)beforeItemID
                              customData:(id)customData;

/**
 * A convenience method that moves a single item in the queue.
 *
 * @param itemID The ID of the item to move.
 * @param beforeItemID The ID of the item that will be located immediately after the reordered list.
 * If the value is @ref kKPGMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the item will be moved to the end of the queue.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueMoveItemWithID:(NSUInteger)itemID beforeItemWithID:(NSUInteger)beforeItemID;

/**
 * Jumps to the item with the specified ID in the queue.
 *
 * @param itemID The ID of the item to jump to.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueJumpToItemWithID:(NSUInteger)itemID;

/**
 * Jumps to the item with the specified ID in the queue.
 *
 * @param itemID The ID of the item to jump to.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueJumpToItemWithID:(NSUInteger)itemID
                           customData:(id)customData;

/**
 * Jumps to the item with the specified ID in the queue.
 *
 * @param itemID The ID of the item to jump to.
 * @param playPosition The initial playback position for the item when it is first played,
 * relative to the beginning of the stream. This value is ignored when the same item is played
 * again, for example when the queue repeats, or the item is later jumped to. In those cases the
 * item's startTime is used.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueJumpToItemWithID:(NSUInteger)itemID
                         playPosition:(NSTimeInterval)playPosition
                           customData:(id)customData;

/**
 * Moves to the next item in the queue.
 *
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueNextItem;

/**
 * Moves to the previous item in the queue.
 *
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queuePreviousItem;

/**
 * Sets the queue repeat mode.
 *
 * @param repeatMode The new repeat mode.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)queueSetRepeatMode:(KPGMediaRepeatMode)repeatMode;

/**
 * Sets the stream volume. The request will fail if there is no current media session.
 *
 * @param volume The new volume, in the range [0.0 - 1.0].
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)setStreamVolume:(float)volume;

/**
 * Sets the stream volume. The request will fail if there is no current media session.
 *
 * @param volume The new volume, in the range [0.0 - 1.0].
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)setStreamVolume:(float)volume customData:(id)customData;

/**
 * Sets whether the stream is muted. The request will fail if there is no current media session.
 *
 * @param muted Whether the stream should be muted or unmuted.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)setStreamMuted:(BOOL)muted;

/**
 * Sets whether the stream is muted. The request will fail if there is no current media session.
 *
 * @param muted Whether the stream should be muted or unmuted.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)setStreamMuted:(BOOL)muted customData:(id)customData;

/**
 * Requests updated media status information from the receiver.
 *
 * @return The KPGRequest object for tracking this request.
 */
- (id<KPGRequest>)requestStatus;

/**
 * Returns the approximate stream position as calculated from the last received stream information
 * and the elapsed wall-time since that update. Returns 0 if the channel is not connected or if no
 * media is currently loaded.
 */
- (NSTimeInterval)approximateStreamPosition;

@end

/**
 * The KPGRemoteMediaClient listener protocol.
 *
 * @since 3.0
 */

@protocol KPGRemoteMediaClientListener <NSObject>

@optional

/**
 * Called when a new media session has started on the receiver.
 *
 * @param client The client.
 * @param sessionID The ID of the new session.
 */
- (void)remoteMediaClient:(id<KPGRemoteMediaClient>)client
didStartMediaSessionWithID:(NSInteger)sessionID;

/**
 * Called when updated media status has been received from the receiver.
 *
 * @param client The client.
 * @param mediaStatus The updated media status. The status can also be accessed as a property of
 * the player.
 */
- (void)remoteMediaClient:(id<KPGRemoteMediaClient>)client
     didUpdateMediaStatus:(id<KPGMediaStatus>)mediaStatus;

/**
 * Called when updated media metadata has been received from the receiver.
 *
 * @param client The client.
 * @param mediaMetadata The updated media metadata. The metadata can also be accessed through the
 * KPGRemoteMediaClient::mediaStatus property.
 */
- (void)remoteMediaClient:(id<KPGRemoteMediaClient>)client
   didUpdateMediaMetadata:(id<KPGMediaStatus>)mediaMetadata;

/**
 * Called when the media playback queue has been updated on the receiver.
 *
 * @param client The client.
 */
- (void)remoteMediaClientDidUpdateQueue:(id<KPGRemoteMediaClient>)client;

/**
 * Called when the media preload status has been updated on the receiver.
 *
 * @param client The client.
 */
- (void)remoteMediaClientDidUpdatePreloadStatus:(id<KPGRemoteMediaClient>)client;

@end

/**
 * The delegate protocol for parsing ad break information from a media status.
 *
 * @since 3.1
 */
@protocol KPGRemoteMediaClientAdInfoParserDelegate <NSObject>
@optional

/**
 * Allows the delegate to determine whether the receiver is playing an ad or not, based on the
 * current media status.
 * @param client The client.
 * @param mediaStatus The current media status.
 * @return YES if the receiver is currently playing an ad, NO otherwise.
 */
- (BOOL)remoteMediaClient:(id<KPGRemoteMediaClient>)client
shouldSetPlayingAdInMediaStatus:(id<KPGMediaStatus>)mediaStatus;

/**
 * Allows the delegate to determine the list of ad breaks in the current content.
 * @param client The client.
 * @param mediaStatus The current media status.
 * @return An array of KPGAdBreakInfo objects representing the ad breaks for this content, or nil
 * if there are no ad breaks.
 */
- (NSArray<id<KPGAdBreakInfo>> *)remoteMediaClient:(id<KPGRemoteMediaClient>)client
                                   shouldSetAdBreaksInMediaStatus:(id<KPGMediaStatus>)mediaStatus;

@end

@protocol KPGRequestDelegate;


typedef NSInteger KPGRequestID;
/**
 * @enum KPGRequestAbortReason
 * Enum defining the reasons that could cause a request to be aborted.
 *
 * @since 3.0
 */
typedef NS_ENUM(NSInteger, KPGRequestAbortReason) {
    /** The request was aborted because a similar and overridding request was initiated. */
    KPGRequestAbortReasonReplaced = 1,
    /** The request was aborted after a call to @ref cancel on this request */
    KPGRequestAbortReasonCancelled = 2,
};
/**
 * An object for tracking an asynchronous request.
 *
 * See KPGRequestDelegate for the delegate protocol.
 *
 * @since 3.0
 */


@protocol KPGRequest <NSObject>

/**
 * The delegate for receiving notifications about the status of the request.
 */
@property(nonatomic, weak, readwrite) id<KPGRequestDelegate> delegate;

/**
 * The unique ID assigned to this request.
 */
@property(nonatomic, assign, readonly) KPGRequestID requestID;

/**
 * The error that caused the request to fail, if any, otherwise <code>nil</code>.
 */
@property(nonatomic, copy, readonly) id<KPGError> error;

/**
 * A flag indicating whether the request is currently in progress.
 */
@property(nonatomic, assign, readonly) BOOL inProgress;

/**
 * Cancels the request. Canceling a request does not guarantee that the request will not complete
 * on the receiver; it simply causes the sender to stop tracking the request.
 */
- (void)cancel;

@end
/**
 * The KPGRequest delegate protocol.
 *
 * @since 3.0
 */
@protocol KPGRequestDelegate <NSObject>

@optional

/**
 * Called when the request has successfully completed.
 *
 * @param request The request.
 */
- (void)requestDidComplete:(id<KPGRequest>)request;

/**
 * Called when the request has failed.
 *
 * @param request The request.
 * @param error The error describing the failure.
 */
- (void)request:(id<KPGRequest>)request didFailWithError:(id<KPGError>)error;

/**
 * Called when the request is no longer being tracked. It does not guarantee that the request has
 * succeed or failed.
 *
 * @param request The request.
 * @param abortReason The reason why the request is no longer being tracked.
 */
- (void)request:(id<KPGRequest>)request didAbortWithReason:(KPGRequestAbortReason)abortReason;

@end

/**
 * Options that affect the discovery of Cast devices and the behavior of Cast sessions.
 *
 * @since 3.0
 */
@protocol KPGCastOptions <NSObject, NSCopying>

/**
 * Constructs a new KPGCastOptions object with the specified receiver application ID.
 *
 * @param applicationID The ID of the receiver application which must be supported by discovered
 * Cast devices, and which will be launched when starting a new Cast session.
 */
- (instancetype)initWithReceiverApplicationID:(NSString *)applicationID;

/**
 * Constructs a new KPGCastOptions object with the specified list of namespaces.
 *
 * @param namespaces A list of namespaces which must be supported by the currently running receiver
 * application on each discovered Cast device.
 */
- (instancetype)initWithSupportedNamespaces:(NSArray<NSString *> *)namespaces;

/**
 * A flag indicating whether the sender device's physical volume buttons should control the
 * session's volume.
 */
@property(nonatomic, assign, readwrite) BOOL physicalVolumeButtonsWillControlDeviceVolume;

/**
 * The receiver launch options to use when starting a Cast session.
 */
@property(nonatomic, copy, readwrite) id<KPGCLaunchOptions> launchOptions;

@end

/**
 * A member device of a multizone group.
 *
 * @since 3.1
 */
@interface KPGMultizoneDevice : NSObject <NSCopying>

/** The unique device ID. */
@property(nonatomic, copy, readonly) NSString *deviceID;

/** The device's friendly name. */
@property(nonatomic, copy, readonly) NSString *friendlyName;

/** The device capabilities. */
@property(nonatomic, assign, readwrite) NSInteger capabilities;

/** The device volume level. */
@property(nonatomic, assign, readwrite) float volumeLevel;

/** Whether the device is muted. */
@property(nonatomic, assign, readwrite) BOOL muted;

/**
 * Initializes the object with the given JSON data.
 */
- (instancetype)initWithJSONObject:(id)JSONObject;

/**
 * Designated initializer.
 *
 * @param deviceID The unique device ID.
 * @param friendlyName The device's friendly name.
 * @param capabilities The device capabilities.
 * @param volume The device volume level.
 * @param muted Whether the device is muted.
 */
- (instancetype)initWithDeviceID:(NSString *)deviceID
                    friendlyName:(NSString *)friendlyName
                    capabilities:(NSInteger)capabilities
                     volumeLevel:(float)volume
                           muted:(BOOL)muted;

@end

@protocol KPGCastSession <NSObject>

/**
 * The device's current "active input" status.
 */
@property(nonatomic, assign, readonly) KPGActiveInputStatus activeInputStatus;

/**
 * The device's current "standby" status.
 */
@property(nonatomic, assign, readonly) KPGStandbyStatus standbyStatus;

/**
 * The metadata for the receiver application that is currently running on the receiver device, if
 * any; otherwise <code>nil</code>.
 */
@property(nonatomic, copy, readonly) id<KPGApplicationMetadata> applicationMetadata;

/**
 * The KPGRemoteMediaClient object that can be used to control media playback in the currently
 * active session, if the session supports the media namespace; otherwise <code>nil</code>.
 */
@property(nonatomic, strong, readonly) id<KPGRemoteMediaClient> remoteMediaClient;

/**
 * Designated initializer. Constructs a new Cast session with the given Cast options.
 *
 * @param device The receiver device.
 * @param sessionID The session ID, if resuming; otherwise <code>nil</code>.
 * @param castOptions The Cast options.
 */
- (instancetype)initWithDevice:(id<KPGDevice>)device
                     sessionID:(NSString *)sessionID
                   castOptions:(id<KPGCastOptions>)castOptions;

/**
 * Registers a channel with the session. If the session is connected and the receiver application
 * supports the channel's namespace, the channel will be automatically connected. If the session is
 * not connected, the channel will remain in a disconnected state until the session is started.
 *
 * @param channel The channel to register.
 * @return <code>YES</code> if the channel was registered successfully, <code>NO</code> otherwise.
 */
- (BOOL)addChannel:(id<KCastChannel>)channel;

/**
 * Removes a previously registered channel from the session.
 *
 * @param channel The channel to unregister.
 * @return <code>YES</code> if the channel was unregistered successfully, <code>NO</code> otherwise.
 */
- (BOOL)removeChannel:(id<KCastChannel>)channel;

/**
 * Adds a KPGCastDeviceStatusListener to this object's list of listeners.
 *
 * @param listener The listener to add.
 */
- (void)addDeviceStatusListener:(id<KPGCastDeviceStatusListener>)listener;

/**
 * Removes a KPGCastDeviceStatusListener from this object's list of listeners.
 *
 * @param listener The listener to remove.
 */
- (void)removeDeviceStatusListener:(id<KPGCastDeviceStatusListener>)listener;

/**
 * Sets the individual device's volume in a multizone group. This is an asynchronous operation.
 *
 * @param volume The new volume, in the range [0.0, 1.0].
 * @param device The multizone device.
 * @return A KPGRequest object for tracking the request.
 */
- (id<KPGRequest>)setDeviceVolume:(float)volume forMultizoneDevice:(KPGMultizoneDevice *)device;

/**
 * Sets the individual device's muted state in a multizone group. This is an asynchronous operation.
 *
 * @param muted The new muted state.
 * @param device The multizone device.
 * @return A KPGRequest object for tracking the request.
 */
- (id<KPGRequest>)setDeviceMuted:(BOOL)muted forMultizoneDevice:(KPGMultizoneDevice *)device;

/**
 * Request multizone status from a multizone group. This is an asynchronous operation. When the
 * multizone status is received, the
 * KPGCastDeviceStatusListener::castSession:didReceiveMultizoneStatus: delegate method will be
 * messaged.
 *
 * @return A KPGRequest object for tracking the request.
 */
- (id<KPGRequest>)requestMultizoneStatus;

@end


/**
 * @enum KPGDeviceStatus
 * Enum defining the device status at the time the device was scanned.
 */
typedef NS_ENUM(NSInteger, KPGDeviceStatus) {
    /** Unknown status. */
    KPGDeviceStatusUnknown = -1,
    /** Idle device status. */
    KPGDeviceStatusIdle = 0,
    /** Busy/join device status. */
    KPGDeviceStatusBusy = 1,
};

/**
 * @enum KPGDeviceCapability
 * Enum defining the capabilities of a receiver device.
 */
typedef NS_ENUM(NSInteger, KPGDeviceCapability) {
    /** The device has video-out capability. */
    KPGDeviceCapabilityVideoOut = 1 << 0,
    /** The device has video-in capability. */
    KPGDeviceCapabilityVideoIn = 1 << 1,
    /** The device has audio-out capability. */
    KPGDeviceCapabilityAudioOut = 1 << 2,
    /** The device has audio-in capability. */
    KPGDeviceCapabilityAudioIn = 1 << 3,
    /** The device has multizone group capability. */
    KPGDeviceCapabilityMultizoneGroup = 1 << 5,
    /** The device has master or fixed volume mode capability. */
    KPGDeviceCapabilityMasterOrFixedVolume = 1 << 11,
    /** The device has attenuation or fixed volume mode capability. */
    KPGDeviceCapabilityAttenuationOrFixedVolume = 1 << 12,
};

@protocol KPGDevice <NSObject, NSCoding, NSCopying>

/** The device's IPv4 address, in dot-notation. Used when making network requests. */
@property(nonatomic, copy, readonly) NSString *ipAddress;

/** The device's service port. */
@property(nonatomic, assign, readonly) uint16_t servicePort;
/** A unique identifier for the device. */
@property(nonatomic, copy, readonly) NSString *deviceID;

/** The device's friendly name. This is a user-assignable name such as "Living Room". */
@property(nonatomic, copy, readwrite) NSString *friendlyName;

/** The device's manufacturer name. */
@property(nonatomic, copy, readwrite) NSString *manufacturer;

/** The device's model name. */
@property(nonatomic, copy, readwrite) NSString *modelName;

/** An array of KPGImage objects containing icons for the device. */
@property(nonatomic, copy, readwrite) NSArray<id<KPGImage>> *icons;

/** The device's status at the time that it was most recently scanned. */
@property(nonatomic, assign, readonly) KPGDeviceStatus status;

/** The status text reported by the currently running receiver application, if any. */
@property(nonatomic, copy, readwrite) NSString *statusText;

/** The device's protocol version. */
@property(nonatomic, copy, readwrite) NSString *deviceVersion;

/** YES if this device is on the local network. */
@property(nonatomic, assign, readonly) BOOL isOnLocalNetwork;

/**
 * The device category, a string that uniquely identifies the type of device. Cast devices have
 * a category of @ref kKPGCastDeviceCategory.
 */
@property(nonatomic, copy, readonly) NSString *category;

/**
 * A globally unique ID for this device. This is a concatenation of the @ref category and
 * @ref deviceID properties.
 */
@property(nonatomic, copy, readonly) NSString *uniqueID;

/**
 * Tests if this device refers to the same physical device as another. Returns <code>YES</code> if
 * both KPGDevice objects have the same category, device ID, IP address, service port, and protocol
 * version.
 */
- (BOOL)isSameDeviceAs:(const id<KPGDevice>)other;

/**
 * Returns <code>YES</code> if the device supports the given capabilities.
 *
 * @param deviceCapabilities A bitwise-OR of one or more of the @ref KPGDeviceCapability constants.
 */
- (BOOL)hasCapabilities:(NSInteger)deviceCapabilities;

/**
 * Sets an arbitrary attribute in the object. May be used by custom device providers to store
 * device-specific information for non-Cast devices.
 *
 * @param attribute The attribute value, which must be key-value coding compliant, and cannot be
 * <code>nil</code>.
 * @param key The key that identifies the attribute. The key is an arbitrary string. It cannot be
 * <code>nil</code>.
 */
- (void)setAttribute:(NSObject<NSCoding> *)attribute forKey:(NSString *)key;

/**
 * Looks up an attribute in the object.
 *
 * @param key The key that identifies the attribute. The key is an arbitrary string. It cannot be
 * <code>nil</code>.
 * @return The value of the attribute, or <code>nil</code> if no such attribute exists.
 */
- (NSObject<NSCoding> *)attributeForKey:(NSString *)key;

/**
 * Removes an attribute from the object.
 *
 * @param key The key that identifies the attribute. The key is an arbitrary string. It cannot be
 * <code>nil</code>.
 */
- (void)removeAttributeForKey:(NSString *)key;

/**
 * Removes all attributes from the object.
 */
- (void)removeAllAttributes;

@end



/**
 * An object describing the traits and capabilities of a session.
 *
 * @since 3.0
 */

@protocol KPGSessionTraits <NSObject, NSCopying, NSCoding>

/**
 * The minimum volume value. Must be non-negative and less than or equal to the maximum volume.
 */
@property(nonatomic, assign, readonly) float minimumVolume;

/**
 * The maximum volume value. Must be non-negative and greater than or equal to the minimum volume.
 */
@property(nonatomic, assign, readonly) float maximumVolume;

/**
 * The volume increment for up/down volume adjustments. May be 0 to indicate fixed volume. Must
 * be non-negative and less than or equal to the difference between the maximum volume and minimum
 * volume.
 */
@property(nonatomic, assign, readonly) float volumeIncrement;

/**
 * Whether the audio can be muted.
 */
@property(nonatomic, assign, readonly) BOOL supportsMuting;

/**
 * Designated initializer.
 */
- (instancetype)initWithMinimumVolume:(float)minimumVolume
                        maximumVolume:(float)maximumVolume
                      volumeIncrement:(float)volumeIncrement
                       supportsMuting:(BOOL)supportsMuting;

/**
 * Convenience initializer. Sets the volume range to [0.0, 1.0], the volume increment to 0.05 (5%),
 * the mutable flag to <code>YES</code>, and the supportsStopCasting flag to <code>NO</code>.
 */
- (instancetype)init;

/**
 * Whether this is a fixed volume device.
 */
- (BOOL)isFixedVolume;

@end


/**
 * An abstract base class representing a session with a receiver device. Subclasses must implement
 * the @ref start, @ref endAndStopCasting:, @ref suspendWithReason:, and @ref resume methods, and
 * must call the appropriate notifier methods (for example, @ref notifyDidStartWithSessionID:) to
 * indicate corresponding changes in the session state. Subclasses may also implement
 * @ref setDeviceVolume: and @ref setDeviceMuted: if the device supports such operations.
 *
 * A session is created and controlled using the session methods in KPGSessionManager, which uses
 * the appropriate KPGDeviceProvider to create the session, and then delegates session requests to
 * that KPGSession object.
 *
 * @since 3.0
 */

@protocol KPGSession <NSObject>

/** The device that this session is associated with. */
@property(nonatomic, strong, readonly) id<KPGDevice> device;

/** The current session ID, if any. */
@property(nonatomic, copy, readonly) NSString *sessionID;

/** The current session connection state. */
@property(nonatomic, assign, readonly) KPGCConnectionState connectionState;

/** A flag indicating whether the session is currently suspended. */
@property(nonatomic, assign, readonly) BOOL suspended;

/** The current device status text. */
@property(nonatomic, copy, readonly) NSString *deviceStatusText;

/** The session traits. */
@property(nonatomic, copy, readonly) id<KPGSessionTraits> traits;

/** The current device volume, in the range [0.0, 1.0]. */
@property(nonatomic, assign, readonly) float currentDeviceVolume;

/** The current device mute state. */
@property(nonatomic, assign, readonly) BOOL currentDeviceMuted;

/**
 * The current media metadata, if any. Will be <code>nil</code> if the session does not support the
 * media namespace or if no media is currently loaded on the receiver.
 */
@property(nonatomic, strong, readonly) id<KPGMediaMetadata> mediaMetadata;

/**
 * Initializes a new session object for the given device.
 *
 * @param device The device.
 * @param traits The session traits.
 * @param sessionID The session ID of an existing session, if this object will be used to resume a
 * session; otherwise <code>nil</code> if it will be used to start a new session.
 */
- (instancetype)initWithDevice:(id<KPGDevice>)device
                        traits:(id<KPGSessionTraits>)traits
                     sessionID:(NSString *)sessionID;

/**
 * Sets the device's volume. This is an asynchronous operation. The default implementation is a
 * no-op.
 *
 * @param volume The new volume.
 */
- (void)setDeviceVolume:(float)volume;

/**
 * Sets the device's mute state. This is an asynchronous operation. The default implementation is a
 * no-op.
 *
 * @param muted The new mute state.
 */
- (void)setDeviceMuted:(BOOL)muted;

@end

@protocol KPGSessionManagerListener;

/**
 * @enum KPGConnectionSuspendReason
 * Enum defining the reasons for a connection becoming suspended.
 */
typedef NS_ENUM(NSInteger, KPGConnectionSuspendReason) {
    /** The connection was suspended because the application is going into the background. */
    KPGConnectionSuspendReasonAppBackgrounded = 1,
    /** The connection was suspended because of a network or protocol error. */
    KPGConnectionSuspendReasonNetworkError = 2
};

@protocol KPGSessionManager <NSObject>

/** The current session, if any. */
@property(nonatomic, strong, readonly) id<KPGSession> currentSession;

/** The current cast session, if any. */
@property(nonatomic, strong, readonly) <KPGCastSession> currentCastSession;

/** The current session connection state. */
@property(nonatomic, assign, readonly) KPGCConnectionState connectionState;

/**
 * Starts a new session with the given device. This is an asynchronous operation.
 *
 * @param device The device to use for this session.
 * @return <code>YES</code> if the operation has been started successfully, <code>NO</code> if
 * there is a session currently established or if the operation could not be started.
 */
- (BOOL)startSessionWithDevice:(id<KPGCDevice>)device;

/**
 * Suspends the current session. This is an asynchronous operation.
 *
 * @param reason The reason for the suspension.
 * @return <code>YES</code> if the operation has been started successfully, <code>NO</code> if
 * there is no session currently established or if the operation could not be started.
 */
- (BOOL)suspendSessionWithReason:(KPGConnectionSuspendReason)reason;

/**
 * Ends the current session. This is an asynchronous operation.
 *
 * @return <code>YES</code> if the operation has been started successfully, <code>NO</code> if
 * there is no session currently established or if the operation could not be started.
 */
- (BOOL)endSession;

/**
 * Ends the current session, optionally stopping casting. This is an asynchronous operation.
 *
 * @param stopCasting Whether casting of content on the receiver should be stopped when the session
 * is ended.
 * @return <code>YES</code> if the operation has been started successfully, <code>NO</code> if
 * there is no session currently established or if the operation could not be started.
 */
- (BOOL)endSessionAndStopCasting:(BOOL)stopCasting;

/**
 * Tests if a session is currently being managed by this session manager, and it is currently
 * connected. This will be <code>YES</code> if the session state is
 * @ref KPGConnectionStateConnected.
 */
- (BOOL)hasConnectedSession;

/**
 * Tests if a Cast session is currently being managed by this session manager, and it is currently
 * connected. This will be <code>YES</code> if the session state is @ref KPGConnectionStateConnected
 * and the session is a Cast session.
 */
- (BOOL)hasConnectedCastSession;

/**
 * Adds a listener for receiving notifications.
 *
 * @param listener The listener to add.
 */
- (void)addListener:(id<KPGSessionManagerListener>)listener;

/**
 * Removes a listener that was previously added with @ref addListener:.
 *
 * @param listener The listener to remove.
 */
- (void)removeListener:(id<KPGSessionManagerListener>)listener;

@end

/**
 * The KPGSessionManager listener protocol. The protocol's methods are all optional. All of the
 * notification methods come in two varieties: one that is invoked for any session type, and one
 * that is invoked specifically for Cast sessions.
 *
 * Listeners are invoked in the order that they were registered. KPGSessionManagerListener instances
 * which are registered by components of the framework itself (such as KPGUIMediaController), will
 * always be invoked <i>after</i> those that are registered by the application for the callbacks
 * KPGSessionManagerListener::sessionManager:willStartSession:,
 * KPGSessionManagerListener::sessionManager:willStartCastSession:,
 * KPGSessionManagerListener::sessionManager:willResumeSession:, and
 * KPGSessionManagerListener::sessionManager:willResumeCastSession:; and <i>before</i> those
 * that are registered by the application for all of the remaining callbacks.
 *
 * @since 3.0
 */
@protocol KPGSessionManagerListener <NSObject>

@optional

/**
 * Called when a session is about to be started.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager willStartSession:(id<KPGSession>)session;

/**
 * Called when a session has been successfully started.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager didStartSession:(id<KPGSession>)session;

/**
 * Called when a Cast session is about to be started.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
  willStartCastSession:(id<KPGCastSession>)session;

/**
 * Called when a Cast session has been successfully started.
 *
 * @param sessionManager The session manager.
 * @param session The Cast session.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
   didStartCastSession:(id<KPGCastSession>)session;

/**
 * Called when a session is about to be ended, either by request or due to an error.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager willEndSession:(id<KPGSession>)session;

/**
 * Called when a session has ended, either by request or due to an error.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 * @param error The error, if any; otherwise nil.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
         didEndSession:(id<KPGSession>)session
             withError:(NSError *)error;

/**
 * Called when a Cast session is about to be ended, either by request or due to an error.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
    willEndCastSession:(id<KPGCastSession>)session;

/**
 * Called when a Cast session has ended, either by request or due to an error.
 *
 * @param sessionManager The session manager.
 * @param session The Cast session.
 * @param error The error, if any; otherwise nil.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
     didEndCastSession:(id<KPGCastSession>)session
             withError:(NSError *)error;

/**
 * Called when a session has failed to start.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 * @param error The error.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
 didFailToStartSession:(id<KPGSession>)session
             withError:(NSError *)error;

/**
 * Called when a Cast session has failed to start.
 *
 * @param sessionManager The session manager.
 * @param session The Cast session.
 * @param error The error.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
didFailToStartCastSession:(id<KPGCastSession>)session
             withError:(NSError *)error;

/**
 * Called when a session has been suspended.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 * @param reason The reason for the suspension.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
     didSuspendSession:(id<KPGSession>)session
            withReason:(KPGConnectionSuspendReason)reason;

/**
 * Called when a Cast session has been suspended.
 *
 * @param sessionManager The session manager.
 * @param session The Cast session.
 * @param reason The reason for the suspension.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
 didSuspendCastSession:(id<KPGCastSession>)session
            withReason:(KPGConnectionSuspendReason)reason;

/**
 * Called when a session is about to be resumed.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager willResumeSession:(id<KPGSession>)session;

/**
 * Called when a session has been successfully resumed.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager didResumeSession:(id<KPGSession>)session;

/**
 * Called when a Cast session is about to be resumed.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
 willResumeCastSession:(id<KPGCastSession>)session;

/**
 * Called when a Cast session has been successfully resumed.
 *
 * @param sessionManager The session manager.
 * @param session The Cast session.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
  didResumeCastSession:(id<KPGCastSession>)session;

/**
 * Called when updated device volume and mute state for a session have been received.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 * @param volume The current volume, in the range [0.0, 1.0].
 * @param muted The current mute state.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
               session:(id<KPGSession>)session
didReceiveDeviceVolume:(float)volume
                 muted:(BOOL)muted;
/**
 * Called when updated device volume and mute state for a Cast session have been received.
 *
 * @param sessionManager The session manager.
 * @param session The Cast session.
 * @param volume The current volume, in the range [0.0, 1.0].
 * @param muted The current mute state.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
           castSession:(id<KPGCastSession>)session
didReceiveDeviceVolume:(float)volume
                 muted:(BOOL)muted;

/**
 * Called when updated device status for a session has been received.
 *
 * @param sessionManager The session manager.
 * @param session The session.
 * @param statusText The new device status text.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
               session:(id<KPGSession>)session
didReceiveDeviceStatus:(NSString *)statusText;

/**
 * Called when updated device status for a Cast session has been received.
 *
 * @param sessionManager The session manager.
 * @param session The Cast session.
 * @param statusText The new device status text.
 */
- (void)sessionManager:(id<KPGSessionManager>)sessionManager
           castSession:(id<KPGCastSession>)session
didReceiveDeviceStatus:(NSString *)statusText;

@end


@protocol KPGGenericChannelDelegate;
/**
 * A generic KPGCastChannel implementation, suitable for use when subclassing is not desired.
 * KPGGenericChannel forwards message and connectivity events to its delegate, and has no
 * processing logic of its own.
 *
 * See KPGGenericChannelDelegate for the delegate protocol.
 */
@protocol KPGGenericChannel <KCastChannel>

/**
 * The delegate for receiving notifications about changes in the channel's state.
 */
@property(nonatomic, weak, readwrite) id<KPGGenericChannelDelegate> delegate;

/**
 * Designated initializer.
 *
 * @param protocolNamespace The namespace for this channel. This namespace must be unique across
 * all channels used by a given application.
 */
- (instancetype)initWithNamespace:(NSString *)protocolNamespace;

@end

/**
 * The KPGGenericChannel delegate protocol.
 */
@protocol KPGGenericChannelDelegate <NSObject>

/**
 * Called when a text message has been received on the channel.
 */
- (void)castChannel:(id<KPGGenericChannel>)channel didReceiveTextMessage:(NSString *)message withNamespace:(NSString *)protocolNamespace;

@optional

/**
 * Called when the channel has been connected, indicating that messages can now be exchanged with
 * the Cast device over the channel.
 */
- (void)castChannelDidConnect:(id<KPGGenericChannel>)channel;

/**
 * Called when the channel has been disconnected, indicating that messages can no longer be
 * exchanged with the Cast device over the channel.
 */
- (void)castChannelDidDisconnect:(id<KPGGenericChannel>)channel;

@end

