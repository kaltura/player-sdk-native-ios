//
//  IMAAdsLoader.h
//  GoogleIMA3
//
//  Copyright (c) 2013 Google Inc. All rights reserved.
//
//  Declares a set of classes used when loading ads.

#import <Foundation/Foundation.h>

#import "IMAAdError.h"
#import "IMAAdsManager.h"
#import "IMAAdsRequest.h"

#pragma mark IMASettings

/// Stores SDK wide settings.  Only instantiated in the SDK.
@interface IMASettings : NSObject

/// Publisher Provided Identification (PPID) sent with ads request.
@property(nonatomic, copy) NSString *ppid;

/// Language specification used for localization. |Language| must be formated as
/// a canonicalized IETF BCP 47 language identifier such as would be returned by
/// [NSLocale preferredLanguages]. Setting this property after it has been sent
/// to the IMAAdsLoader will be ignored and a warning will be logged.
@property(nonatomic, copy) NSString *language;

@end

#pragma mark IMAAdsLoadedData

/// Ad loaded data that is returned when the ads loader loads the ad.
@interface IMAAdsLoadedData : NSObject

/// The ads manager instance created by the ads loader.
@property(nonatomic, readonly) IMAAdsManager *adsManager;

/// The user context specified in the ads request.
@property(nonatomic, readonly) id userContext;

@end

#pragma mark -
#pragma mark IMAAdLoadingErrorData

/// Ad error data that is returned when the ads loader fails to load the ad.
@interface IMAAdLoadingErrorData : NSObject

/// The ad error that occured while loading the ad.
@property(nonatomic, readonly) IMAAdError *adError;

/// The user context specified in the ads request.
@property(nonatomic, readonly) id userContext;

@end

#pragma mark -
#pragma mark IMAAdsLoaderDelegate

@class IMAAdsLoader;

/// Delegate object that receives state change callbacks from IMAAdsLoader.
@protocol IMAAdsLoaderDelegate

/// Called when ads are successfully loaded from the ad servers by the loader.
- (void)adsLoader:(IMAAdsLoader *)loader
    adsLoadedWithData:(IMAAdsLoadedData *)adsLoadedData;

/// Error reported by the ads loader when ads loading failed.
- (void)adsLoader:(IMAAdsLoader *)loader
    failedWithErrorData:(IMAAdLoadingErrorData *)adErrorData;

@end

#pragma mark -

/// The IMAAdsLoader class allows the requesting of ads from the ad server.
/// Use the delegate to receive the loaded ads or loading error
/// in case of failure.
@interface IMAAdsLoader : NSObject

/// Returns the SDK version.
+ (NSString *)sdkVersion;

/// Initializes the adsLoader with SDK wide |settings|.
- (instancetype)initWithSettings:(IMASettings *)settings;

/// Request ads from the ad server.
- (void)requestAdsWithRequest:(IMAAdsRequest *)request;

/// Signal to the SDK that the content has completed. The SDK will play
/// post-rolls at this time, if any are scheduled.
- (void)contentComplete;

/// Delegate that receives the result of the ad request.
@property(nonatomic, weak) id<IMAAdsLoaderDelegate> delegate;

/// SDK-wide settings.  Note that certain settings will only be evaluated
/// during initialization of the adsLoader.
@property(nonatomic, retain) IMASettings *settings;

@end
