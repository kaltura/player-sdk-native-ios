//
//  KALChromecastPlayer.h
//  PlayerSDK
//
//  Created by Eliza Sapir on 5/12/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KalturaBasicPlayer.h"
#import "PlayerSDK/ChromecastDeviceController.h"

@interface KALChromecastPlayer : KalturaBasicPlayer {
    ChromecastDeviceController *chromecastDeviceController;
    BOOL showChromecastButton;
}

@property (nonatomic) ChromecastDeviceController *chromecastDeviceController;

@end
