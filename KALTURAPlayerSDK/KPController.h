//
//  KPMoviePlayerController.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 7/2/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPMediaPlayback.h"

// -----------------------------------------------------------------------------
// Media Player Types

typedef NS_ENUM(NSInteger, KPMediaPlaybackState) {
    KPMediaPlaybackStateUnknown,
    KPMediaPlaybackStateLoaded,
    KPMediaPlaybackStateReady,
    /* Playback is currently stopped. */
    KPMediaPlaybackStateStopped,
    /* Playback is currently under way. */
    KPMediaPlaybackStatePlaying,
    /* Playback is currently paused. */
    KPMediaPlaybackStatePaused,
    /* Playback is currently ended. */
    KPMediaPlaybackStateEnded,
    ///@todo
    /* Playback is temporarily interrupted, perhaps because the buffer ran out of content. */
    KPMediaPlaybackStateInterrupted,
    /* The movie player is currently seeking towards the end of the movie. */
    KPMediaPlaybackStateSeekingForward,
    /* The movie player is currently seeking towards the beginning of the movie. */
    KPMediaPlaybackStateSeekingBackward
};

///@todo
typedef NS_OPTIONS(NSUInteger, KPMediaLoadState) {
    /* The load state is not known. */
    KPMediaLoadStateUnknown        = 0,
    /* The buffer has enough data that playback can begin, but it may run out of data before playback finishes. */
    KPMediaLoadStatePlayable       = 1 << 0,
    /* Enough data has been buffered for playback to continue uninterrupted. */
    KPMediaLoadStatePlaythroughOK  = 1 << 1, // Playback will be automatically started in this state when shouldAutoplay is YES
    /* The buffering of data has stalled. */
    KPMediaLoadStateStalled        = 1 << 2, // Playback will be automatically paused in this state, if started
};

// -----------------------------------------------------------------------------
// Media Player Notifications

/* Posted when the playback state changes, either programatically or by the user. */
extern NSString * const KPMediaPlaybackStateDidChangeNotification;

// -----------------------------------------------------------------------------
// Media Player Keys
extern NSString * const KMediaPlaybackStateKey;

@protocol KPMediaPlayback;

@protocol KPControllerDelegate <NSObject>

/*!
 @method        sendKPNotification:withParams:
 @abstract      Call a KDP notification (perform actions using this API, for example: play, pause, changeMedia, etc.) (required)
 */

- (void)sendKPNotification:(NSString *)kpNotificationName withParams:(NSString *)kpParams;
- (NSTimeInterval)duration;
- (NSTimeInterval)currentPlaybackTime;
- (float)volume;
- (void)setVolume:(float)value;

@end

@interface KPController : NSObject <KPMediaPlayback>

@property (nonatomic, weak) id<KPControllerDelegate> delegate;

/* The URL that points to the movie file. */
@property (nonatomic, copy) NSURL *contentURL;

/// @return Duration of the current video
@property (nonatomic, readonly) NSTimeInterval duration;
/* The volume of the player. */
@property (nonatomic) float volume NS_AVAILABLE(10_7, 7_0);

/// Perfoms seek to the currentPlaybackTime and returns the currentPlaybackTime
@property (nonatomic) NSTimeInterval currentPlaybackTime;

/* The current playback state of the movie player. (read-only)
 The playback state is affected by programmatic calls to play, pause, or stop the kPlayer. */
@property (nonatomic, readonly) KPMediaPlaybackState playbackState;
/* The current load state of the kPlayer. (read-only). */
@property (nonatomic, readonly) KPMediaLoadState loadState;

- (void)seek:(NSTimeInterval)playbackTime;
///todo::
//- (void)addPeriodicTimeForInterval:(NSTimeInterval)interval usingBlock:(void (^)(NSTimeInterval time))block;

@end

