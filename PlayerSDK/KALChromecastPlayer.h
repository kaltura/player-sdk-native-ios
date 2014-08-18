//
//  KALChromecastPlayer.h
//  PlayerSDK
//
//  Created by Eliza Sapir on 5/12/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KALPlayer.h"
#import "ChromecastDeviceController.h"
//#import "KALChromecastPlayer.h"

@interface KALChromecastPlayer : NSObject  <KalturaPlayer> {
    ChromecastDeviceController *chromecastDeviceController;
    BOOL showChromecastButton;
}

@property (nonatomic) ChromecastDeviceController *chromecastDeviceController;
@property (nonatomic, assign) id<KDPApi> kDPApi;

@end
