//
//  DeviceParamsHandler.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/9/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

#define isIOS(version) [[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."][0] intValue] == (version)
#define isIpad [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad

void setUserAgent();
NSString *advertiserID();

@interface DeviceParamsHandler : NSObject

@end
