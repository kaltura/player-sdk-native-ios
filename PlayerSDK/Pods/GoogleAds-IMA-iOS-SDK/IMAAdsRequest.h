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

/// Initializes an ads request instance with the |adTagUrl| and
/// |adDisplayContainer| specified.
- (instancetype)initWithAdTagUrl:(NSString *)adTagUrl
              adDisplayContainer:(IMAAdDisplayContainer *)adDisplayContainer
                     userContext:(id)userContext;

@end
