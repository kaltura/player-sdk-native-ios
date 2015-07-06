//
//  KPMoviePlayerController.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 7/2/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPMediaPlayback.h"

@protocol KPMediaPlayback;

@protocol KPControllerDelegate <NSObject>

/*!
 @method        sendKPNotification:withParams:
 @abstract      Call a KDP notification (perform actions using this API, for example: play, pause, changeMedia, etc.) (required)
 */
- (void)sendKPNotification:(NSString *)kpNotificationName withParams:(NSString *)kpParams;

@end

@interface KPController : NSObject <KPMediaPlayback>

@property (nonatomic, weak) id<KPControllerDelegate> delegate;

@end

