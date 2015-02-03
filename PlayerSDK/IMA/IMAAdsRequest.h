//
//  IMAAdsRequest.h
//  GoogleIMA3
//
//  Copyright (c) 2013 Google Inc. All rights reserved.
//
//  Declares a simple ad request class.

#import <Foundation/Foundation.h>

#import "IMAAdDisplayContainer.h"

/// Data class describing the ad request.
@interface IMAAdsRequest : NSObject

/// The ad request URL set.
@property(nonatomic, readonly, copy) NSString *adTagUrl;

/// The user context.
@property(nonatomic, readonly) id userContext;

/// Specifies whether the player intends to start the content and ad in
/// response to a user action or whether they will be automatically played.
/// Changing this setting will have no impact on ad playback.
@property(nonatomic) BOOL adWillAutoPlay;

/// Initializes an ads request instance with the |adTagUrl| and
/// |adDisplayContainer| specified.
- (instancetype)initWithAdTagUrl:(NSString *)adTagUrl
              adDisplayContainer:(IMAAdDisplayContainer *)adDisplayContainer
                     userContext:(id)userContext;

@end
