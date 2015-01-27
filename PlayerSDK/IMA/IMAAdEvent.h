/*! \file IMAAdEvent.h
 *  GoogleIMA3
 *
 *  Copyright (c) 2013 Google Inc. All rights reserved.
 *
 *  Defines a data object used to convey information during ad playback.
 *  This object is sent to the IMAAdsManager delegate.
 */

#import <Foundation/Foundation.h>

#import "IMAAd.h"

/// Different event types sent by the IMAAdsManager to its delegate.
typedef enum {
  /// All ads managed by the ads manager have completed.
  kIMAAdEvent_ALL_ADS_COMPLETED,
  /// Ad clicked.
  kIMAAdEvent_CLICKED,
  /// Single ad has finished.
  kIMAAdEvent_COMPLETE,
  /// First quartile of a linear ad was reached.
  kIMAAdEvent_FIRST_QUARTILE,
  /// An ad was loaded.
  kIMAAdEvent_LOADED,
  /// Midpoint of a linear ad was reached.
  kIMAAdEvent_MIDPOINT,
  /// Ad paused.
  kIMAAdEvent_PAUSE,
  /// Ad resumed.
  kIMAAdEvent_RESUME,
  /// Ad has skipped.
  kIMAAdEvent_SKIPPED,
  /// Ad has started.
  kIMAAdEvent_STARTED,
  /// Ad tapped.
  kIMAAdEvent_TAPPED,
  /// Third quartile of a linear ad was reached.
  kIMAAdEvent_THIRD_QUARTILE
} IMAAdEventType;

/// Simple data class used to transport ad playback information.
@interface IMAAdEvent : NSObject

/// Type of the event.
@property(nonatomic, readonly) IMAAdEventType type;

/// Data of the ad relevant to the event. Can be nil.
@property(nonatomic, readonly) IMAAd *ad;

@end
