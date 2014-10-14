// Copyright 2013 Google Inc.

#import <Foundation/Foundation.h>

#import "GCKDefines.h"

@protocol GCKCastChannelHandler;

/**
 * A GCKCastChannel is used to send and receive messages that are tagged with a specific
 * namespace. In this way, multiple channels may be multiplexed over a single connection
 * to the device.
 * <p>
 * Subclasses should implement the @link GCKCastChannel#didReceiveTextMessage: @endlink and/or
 * @link GCKCastChannel#didReceiveBinaryMessage: @endlink methods to process incoming messages,
 * and will typically provide additional methods for sending messages that are specific to a
 * given namespace.
 *
 * @ingroup Messages
 */
GCK_EXPORT
@interface GCKCastChannel : NSObject

/** The channel's namespace. */
@property(nonatomic, copy, readonly) NSString *protocolNamespace;

@property(nonatomic, readonly) BOOL isConnected;

/**
 * Designated initializer. Constructs a new GCKCastChannel with the given namespace.
 *
 * @param protocolNamespace The namespace.
 */
- (id)initWithNamespace:(NSString *)protocolNamespace;

/**
 * Called when a text message has been received for this channel. The default implementation is a
 * no-op.
 *
 * @param message The message string.
 */
- (void)didReceiveTextMessage:(NSString *)message;

/**
 * Sends a text message.
 *
 * @param message The message string.
 * @return <code>YES</code> on success or <code>NO</code> if the message could not be sent (because
 * the handler is not connected, or because the send buffer is too full at the moment).
 */
- (BOOL)sendTextMessage:(NSString *)message;

/**
 * Generates a request ID for a new message.
 */
- (NSInteger)generateRequestID;

/**
 * A convenience method which wraps generateRequestID in an NSNumber.
 */
- (NSNumber *)generateRequestNumber;

/**
 * Called when this channel is added to a connected handler, or when then disconnected
 * handler to which this channel has been added becomes connected.
 */
- (void)didConnect;

/**
 * Called when this channel is removed from a connected handler, or when then connected
 * handler to which this channel has been added becomes disconnected.
 */
- (void)didDisconnect;

@end

