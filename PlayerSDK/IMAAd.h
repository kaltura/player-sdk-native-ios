//
//  IMAAd.h
//  GoogleIMA3
//
//  Copyright (c) 2013 Google Inc. All rights reserved.
//
//  Represents metadata of a single ad. The user can use this metadata for
//  positioning nonlinear ads (isLinear, width, height), internal tracking
//  (adId, adTitle) or custom behavior (traffickingParameters).

#import <Foundation/Foundation.h>

#import "IMAAdPodInfo.h"

/// Data object representing a single ad.
@interface IMAAd : NSObject

/// The ad ID as specified in the VAST response.
@property(nonatomic, readonly) NSString *adId;

/// The ad title from the VAST response.
@property(nonatomic, readonly) NSString *adTitle;

/// The ad description.
@property(nonatomic, readonly) NSString *adDescription;

/// Content type of the currently selected creative. For linear creatives
/// returns the content type of the currently selected media file. Returns
/// empty string if no creative or media file is selected on this ad.
@property(nonatomic, readonly) NSString *contentType;

/// The duration of the ad from the VAST response.
@property(nonatomic, readonly) NSTimeInterval duration;

/// The UI elements that will be displayed during ad playback.
@property(nonatomic, readonly) NSArray *uiElements;

/// The size of the ad asset. For non-linear ads, this is the actual width and
/// height of the ad representation. For linear ads, since
/// they scale seamlessly, we currently return 0 for width and height.
@property(nonatomic, readonly) int width;
@property(nonatomic, readonly) int height;

/// Specifies whether the ad is linear or non-linear.
@property(nonatomic, readonly, getter=isLinear) BOOL linear;

/// Specifies whether the ad is skippable.
@property(nonatomic, readonly, getter=isSkippable) BOOL skippable;

/// Set of ad podding properties.
@property(nonatomic, readonly) IMAAdPodInfo *adPodInfo;

/// String representing custom trafficking parameters from the VAST
/// response.
@property(nonatomic, readonly) NSString *traffickingParameters;

@end
