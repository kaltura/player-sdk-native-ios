// Copyright 2013 Google Inc.

#import <Foundation/Foundation.h>

/**
 * An object that encapsulates metadata for a piece of content.
 *
 * @ingroup Messages
 */
@interface GCKContentMetadata : NSObject <NSCopying>

/** The title of the content. */
@property(nonatomic, copy, readwrite) NSString *title;

/** The URL to an image for the content. */
@property(nonatomic, copy, readwrite) NSURL *imageURL;

/** Any optional application-specific information describing the content. */
@property(nonatomic, copy, readwrite) NSDictionary *contentInfo;

/** Designated initializer. */
- (id)initWithTitle:(NSString *)title
           imageURL:(NSURL *)imageURL
        contentInfo:(NSDictionary *)contentInfo;

@end
