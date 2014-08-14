// Copyright 2013 Google Inc.

#import "GCKMediaMetadata.h"

/**
 * A class that aggregates metadata about a music track.
 */
@interface GCKMusicTrackMetadata : GCKMediaMetadata

/**
 * The album title.
 */
@property(nonatomic, copy, readwrite) NSString *albumTitle;

/**
 * The artist name.
 */
@property(nonatomic, copy, readwrite) NSString *artist;

/**
 * The track number.
 */
@property(nonatomic, readwrite) NSUInteger trackNumber;

/**
 * The disc number.
 */
@property(nonatomic, readwrite) NSUInteger discNumber;

/** @cond INTERNAL */

- (id)initWithJSONObject:(id)JSONObject;
- (NSMutableDictionary *)JSONObjectAsMutableDictionary;

/** @endcond */

@end
