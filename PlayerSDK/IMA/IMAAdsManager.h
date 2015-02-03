//
//  IMAAdsManager.h
//  GoogleIMA3
//
//  Copyright (c) 2013 Google Inc. All rights reserved.
//
//  Declares IMAAdsManager interface that manages ad playback.
//  The interface represents an abstract API. There can be one or more ads
//  managed by a single ads manager.
//  The implementing code should respond to the callbacks as defined in
//  IMAAdsManagerDelegate.
//
//  A typical ad playback session:
//    1. Ads manager is retrieved. Delegate is set.
//    2. [adsManager initialize...];  - ad is initialized and loads.
//    3. delegate.didReceiveAdEvent is called with a kIMAAdEventLoaded event.
//    4. [adsManager start];
//    5. delegate.adsManagerDidRequestContentPause: is called. The content
//       playback should pause now.
//    6. Ad display container master view is unhidden and playback starts.
//    7. delegate.didReceiveAdEvent is called with ad events.
//    8. Ad finishes.
//    9. delegate.adsManagerDidRequestContentResume: is called. The content
//       playback should resume now.
//    10. delegate.didReceiveAdEvent: is called with the
//        kIMAAdEvent_ALL_ADS_COMPLETED event.
//        It is possible to detach the delegate and destroy the ads manager.
//
//  If multiple ads are managed by the ads manager, steps 5-9 may repeat several
//  times. Step 5 will happen at times predetermined by the ads server.
//  The implementing code should listen to callbacks until
//  kIMAAdEvent_ALL_ADS_COMPLETED is received.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "IMAAdError.h"
#import "IMAAdEvent.h"
#import "IMAAdPlaybackInfo.h"
#import "IMAAdsRenderingSettings.h"
#import "IMAContentPlayhead.h"

@class IMAAdsManager;

#pragma mark IMAAdsManagerDelegate

/// A callback protocol for IMAAdsManager.
@protocol IMAAdsManagerDelegate

/// Called when there is an IMAAdEvent.
- (void)adsManager:(IMAAdsManager *)adsManager
    didReceiveAdEvent:(IMAAdEvent *)event;

/// Called when there was an error playing the ad.
/// Only resume playback when didRequestContentResumeForAdsManager: is called.
/// Continue to listen for callbacks until didReceiveAdEvent: with
/// kIMAAdEvent_ALL_ADS_COMPLETED is called.
- (void)adsManager:(IMAAdsManager *)adsManager
    didReceiveAdError:(IMAAdError *)error;

/// Called when an ad is ready to play.
/// The implementing code should pause the content playback and prepare the UI
/// for ad playback.
- (void)adsManagerDidRequestContentPause:(IMAAdsManager *)adsManager;

/// Called when an ad has finished or an error occurred during the playback.
/// The implementing code should resume the content playback.
- (void)adsManagerDidRequestContentResume:(IMAAdsManager *)adsManager;

@optional
/// @deprecated Replaced by adsManager:adDidProgressToTime:totalTime:
- (void)adDidProgressToTime:(NSTimeInterval)mediaTime
                  totalTime:(NSTimeInterval)totalTime;

/// Called every 200ms to provide time updates for the current ad.
- (void)adsManager:(IMAAdsManager *)adsManager
    adDidProgressToTime:(NSTimeInterval)mediaTime
              totalTime:(NSTimeInterval)totalTime;

@end

#pragma mark -
#pragma mark IMAAdsManager

/// The IMAAdsManager class is responsible for playing ads.
@interface IMAAdsManager : NSObject

/// The delegate to notify with events during ad playback.
@property(nonatomic, assign) NSObject<IMAAdsManagerDelegate> *delegate;

/// List of content time offsets at which ad breaks are scheduled.
/// Array of NSNumber double values in seconds.
/// Empty NSArray for single ads or if no ad breaks are scheduled.
@property(nonatomic, readonly) NSArray *adCuePoints;

/// Groups various properties about the linear ad playback.
/// See |IMAAdPlaybackInfo|.
@property(nonatomic, readonly) id<IMAAdPlaybackInfo> adPlaybackInfo;

/// Initializes and loads the ad. Pass in |contentPlayhead| to
/// enable content tracking and automatically scheduled ad breaks. Use nil
/// to disable this feature.
/// Pass in |adsRenderingSettings| to influence ad rendering. Use nil to
/// default to standard rendering.
- (void)initializeWithContentPlayhead:
    (NSObject<IMAContentPlayhead> *)contentPlayhead
                 adsRenderingSettings:
    (IMAAdsRenderingSettings *)adsRenderingSettings;

/// Starts advertisement playback.
- (void)start;

/// Pauses advertisement.
- (void)pause;

/// Resumes the advertisement.
- (void)resume;

/// Causes the ads manager to stop the ad and clean its internal state.
- (void)destroy;

@end
