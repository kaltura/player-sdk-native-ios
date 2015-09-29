//
//  CCKPlayer.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 6/14/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPlayerController.h"
#import "ChromecastDeviceController.h"

@interface KCCPlayer : NSObject <KPlayer, ChromecastDeviceControllerDelegate>

/* The device manager used for the currently casting media. */
@property(strong, nonatomic) ChromecastDeviceController *chromecastDeviceController;

@end
