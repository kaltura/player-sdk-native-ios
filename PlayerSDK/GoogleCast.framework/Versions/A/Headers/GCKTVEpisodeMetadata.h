// Copyright 2013 Google Inc.

#import "GCKMediaMetadata.h"

/**
 * A class that aggregates metadata about a TV show episode.
 */
@interface GCKTVEpisodeMetadata : GCKMediaMetadata

/**
 * The series title.
 */
@property(nonatomic, copy, readwrite) NSString *seriesTitle;

/**
 * The season number.
 */
@property(nonatomic, readwrite) NSUInteger seasonNumber;

/**
 * The episode number.
 */
@property(nonatomic, readwrite) NSUInteger episodeNumber;

/** @cond INTERNAL */

- (id)initWithJSONObject:(id)JSONObject;
- (NSMutableDictionary *)JSONObjectAsMutableDictionary;

/** @endcond */

@end
