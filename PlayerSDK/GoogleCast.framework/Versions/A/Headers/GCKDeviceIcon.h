// Copyright 2013 Google Inc.

#import <Foundation/Foundation.h>

/**
 * An object representing a first-screen device icon.
 *
 * @ingroup Discovery
 */
@interface GCKDeviceIcon : NSObject<NSCopying, NSCoding>

/** The icon's width, in pixels. */
@property(nonatomic, readonly) NSUInteger width;

/** The icon's height, in pixels. */
@property(nonatomic, readonly) NSUInteger height;

/** The icon's depth, in bits. */
@property(nonatomic, readonly) NSUInteger depth;

/** The icon's URL. */
@property(nonatomic, copy, readonly) NSURL *url;

/**
 * Designated initializer. Constructs a new GCKDeviceIcon with the given property values.
 */
- (id)initWithWidth:(NSUInteger)width
             height:(NSUInteger)height
              depth:(NSUInteger)depth
                url:(NSURL *)url;

@end
