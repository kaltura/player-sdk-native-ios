// Copyright 2013 Google Inc.

@class GCKImage;

/** @cond INTERNAL */

typedef NS_ENUM(NSInteger, GCKMediaMetadataType) {
  GCKMediaMetadataTypeGeneric = 0,
  GCKMediaMetadataTypeMovie = 1,
  GCKMediaMetadataTypeTVEpisode = 2,
  GCKMediaMetadataTypeMusicTrack = 3,
};

/** @endcond */

/**
 * A class that aggregates metadata about a generic media item. See the subclasses of this class
 * for more specific media types.
 */
@interface GCKMediaMetadata : NSObject

/**
 * The title.
 */
@property(nonatomic, copy, readwrite) NSString *title;

/**
 *The subtitle.
 */
@property(nonatomic, copy, readwrite) NSString *subtitle;

/**
 * The release year.
 */
@property(nonatomic, readwrite) NSUInteger releaseYear;

/**
 * Gets the list of images.
 */
- (NSArray *)mediaImages;

/**
 * Clears the list of images.
 */
- (void)clearMediaImages;

/**
 * Adds an image to the list of images.
 */
- (void)addMediaImage:(GCKImage *)mediaImage;

/** @cond INTERNAL */

/**
 * The metadata type used in the JSON representation for this class.
 */
+ (GCKMediaMetadataType)metadataType;

/**
 * Create and initialize a GCKMediaMetadata of the correct type for this JSON representation.
 * Returns nil if no such type.
 */
+ (GCKMediaMetadata *)metadataWithJSONObject:(id)JSONObject;

/**
 * Initialize this object with its JSON representation.
 */
- (id)initWithJSONObject:(id)JSONObject;

/**
 * Create a JSON object which can serialized with NSJSONSerialization to pass to the receiver.
 */
- (id)JSONObject;

/**
 * Create a mutable dictionary which will be used to provide the JSON object for this object.
 * This allows subclasses to easily extend the base JSONObject.
 */
- (NSMutableDictionary *)JSONObjectAsMutableDictionary;

/** @endcond */

@end
