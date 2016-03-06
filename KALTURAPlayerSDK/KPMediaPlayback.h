//
//  KPMediaPlayback.h
//  KalturaUnified
//
//  Created by Eliza Sapir on 7/5/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KMediaPlayerDefines.h"

/*!
 @protocol		KPMediaPlayback
 
 @abstract
	The KPMediaPlayback protocol defines the interface adopted by the KPController class for controlling media playback. This protocol supports basic transport operations including start and pause, and also lets you seek forward and back through a movie or to a specific point in its timeline.
 */

@protocol KPMediaPlayback

// Prepares the current queue for playback, interrupting any active (non-mixible) audio sessions.
// Automatically invoked when -play is called if the player is not already prepared.
- (void)prepareToPlay;

/*!
 @method        prepareToPlay:
 @abstract      Prepares a Kaltura player for playback. (required)
 
 If a Kaltura player is not already prepared to play when you call the play method, that method automatically calls this method. However, to minimize playback delay, call this method before you call play.
 */
@property(nonatomic, readonly) BOOL isPreparedToPlay;

/*!
 @method        play:
 @abstract      Initiates playback of the current item. (required)
 
 If playback was previously paused, this method resumes playback where it left off; otherwise, this method plays the first available item, from the beginning.
 If a Kaltura player is not prepared for playback when you call this method, this method first prepares the Kaltura player and then starts playback. To minimize playback delay, call the prepareToPlay method before you call this method.
 */
- (void)play;

/*!
 @method        pause:
 @abstract      Pauses playback of the current item. (required)
 
 If playback is not currently underway, this method has no effect. To resume playback of the current item from the pause point, call the play method.
 */
- (void)pause;

/*!
 @method        replay:
 @abstract      replay playback of the current item. (required)
 
 This method initiates playback from the beginning of the current item.
 */
- (void)replay;

/* The current position of the playhead. (required) */
@property(nonatomic) NSTimeInterval currentPlaybackTime;

/* The current playback rate for the player. (required) */
@property(nonatomic) float currentPlaybackRate;

@optional
// The seeking rate will increase the longer scanning is active.

/*!
 @method        beginSeekingForward:
 @abstract      Begins seeking forward through the media content. (required)
 */
- (void)beginSeekingForward;

/*!
 @method        beginSeekingBackward:
 @abstract      Begins seeking backward through the media content. (required)
 */
- (void)beginSeekingBackward;

/*!
 @method        endSeeking:
 @abstract      Ends forward and backward seeking through the media content. (required)
 */
- (void)endSeeking;

@end