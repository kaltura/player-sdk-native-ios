//
//  KALPlayer.h
//  KalPlayerSDK
//
//  Created by Eliza Sapir on 8/13/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "KalPlayerViewController.h"

@interface KALPlayer : MPMoviePlayerController <KalturaPlayer, KalPlayerViewControllerDelegate>

@end
