//
//  KPController_Private.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 7/26/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPController.h"

@interface KPController ()
@property (nonatomic, readwrite) KPMediaPlaybackState playbackState;

#pragma mark - audio tracks & subtitle tracks
@property (nonatomic, readwrite) NSInteger currentAudioTrack;
@property (nonatomic, readwrite) NSArray *audioTracks;

@property (nonatomic, readwrite) NSInteger currentSubtitleTrack;
@property (nonatomic, readwrite) NSArray *subtitleTracks;

@end
