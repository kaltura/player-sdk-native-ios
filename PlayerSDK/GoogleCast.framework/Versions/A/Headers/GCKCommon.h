// Copyright 2014 Google Inc.

#import <Foundation/Foundation.h>

#import "GCKDefines.h"

/**
 * An invalid request ID; if a method returns this request ID, it means that the request could
 * not be made.
 */
GCK_EXTERN const NSInteger kGCKInvalidRequestID;

/**
 * An enum describing the active input status states.
 */
typedef NS_ENUM(NSInteger, GCKActiveInputStatus) {
  /**
   * The active input status is unknown.
   */
  GCKActiveInputStatusUnknown = -1,
  /**
   * The input is inactive.
   */
  GCKActiveInputStatusInactive = 0,
  /**
   * The input is active.
   */
  GCKActiveInputStatusActive = 1,
};

/**
 * An enum describing the standby status states.
 */
typedef NS_ENUM(NSInteger, GCKStandbyStatus) {
  /**
   * The standby status is unknown.
   */
  GCKStandbyStatusUnknown = -1,
  /**
   * The device is not in standby mode.
   */
  GCKStandbyStatusInactive = 0,
  /**
   * The device is in standby mode.
   */
  GCKStandbyStatusActive = 1,
};
