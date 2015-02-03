//
//  IMAAVPlayerContentPlayhead.h
//  GoogleIMA3
//
//  Copyright (c) 2013 Google Inc. All rights reserved.
//
//  Declares IMAAVPlayerContentPlayhead, a wrapper for tracking AVPlayer-based
//  video players.

#import <AVFoundation/AVFoundation.h>

#import "IMAContentPlayhead.h"

/// An implementation of IMAContentPlayhead for AVPlayer. Use this class to
/// provide content tracking if your content player of choice is an AVPlayer
/// or its subclass.
@interface IMAAVPlayerContentPlayhead : NSObject<IMAContentPlayhead>

/// Initializes with the |player| to track. It will attach a periodic time
/// observer to the player immediately.
- (instancetype)initWithAVPlayer:(AVPlayer *)player;

@end
