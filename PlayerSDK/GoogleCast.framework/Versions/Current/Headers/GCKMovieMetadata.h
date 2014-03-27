// Copyright 2013 Google Inc.

#import "GCKMediaMetadata.h"

/**
 * A class that aggregates metadata about a movie.
 */
@interface GCKMovieMetadata : GCKMediaMetadata

/**
 * The studio name.
 */
@property(nonatomic, copy, readwrite) NSString *studio;

/** @cond INTERNAL */

- (id)initWithJSONObject:(id)JSONObject;
- (NSMutableDictionary *)JSONObjectAsMutableDictionary;

/** @endcond */

@end
