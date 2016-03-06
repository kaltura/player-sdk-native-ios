//
//  DeviceParamsHandler.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/9/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/*!
 * @function isIOS
 *
 * @abstract
 * Checks if the device runs on the requested OS version.
 *
 *
 * @param int
 * The requested OS version
 *
 *  @return BOOL YES if the OS is equal or bigger
 */
#define isIOS(version) [[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."][0] intValue] >= (version)
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


/*!
 * @function isIpad
 *
 * @abstract
 * Checks if the device is iPad.
 *
 *  @return BOOL YES if the device is iPad
 */
#define isIpad [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad


#define extractDictionary(fileName, fileType) [NSDictionary dictionaryWithContentsOfFile: [ [NSBundle mainBundle] pathForResource: (fileName) ofType: (fileType)]]

#define _deviceOrientation [UIDevice currentDevice].orientation

#define _statusBarOrientation [UIApplication sharedApplication].statusBarOrientation

#define screenSize [[UIScreen mainScreen] bounds].size

#define screenOrigin [[UIScreen mainScreen] bounds].origin

void setUserAgent();
NSString *appVersion();
BOOL isDeviceOrientation(UIDeviceOrientation orientation);
BOOL isStatusBarOrientation(UIInterfaceOrientation orientation);

BOOL compareOrientations(UIDeviceOrientation compareTo, UIDeviceOrientation orientations, ...);

CGRect screenBounds();

@interface DeviceParamsHandler : NSObject
+ (BOOL)compareOrientation:(UIDeviceOrientation)compareTo listOfOrientations:(UIDeviceOrientation)list, ...;
@end
