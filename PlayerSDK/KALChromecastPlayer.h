//
//  KALChromecastPlayer.h
//  PlayerSDK
//
//  Created by Eliza Sapir on 5/12/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KALPlayer.h"
#import "ChromecastDeviceController.h"

@interface KALChromecastPlayer : KALPlayer {
    ChromecastDeviceController *chromecastDeviceController;
    BOOL showChromecastButton;
}

@property (nonatomic) ChromecastDeviceController *chromecastDeviceController;

@end
