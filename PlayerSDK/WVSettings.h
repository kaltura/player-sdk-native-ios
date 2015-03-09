//
//  WVSettings.h
//  Kaltura
//
//  Created by Eliza Sapir on 6/3/13.
//
//

#if !(TARGET_IPHONE_SIMULATOR)

#import <Foundation/Foundation.h>
#import "WViPhoneAPI.h"

@interface WVSettings : NSObject

-(WViOsApiStatus)initializeWD: (NSString*) key;
- (void) stopWV;
- (void)playMovieFromUrl: (NSString *)videoUrlString;

@end

#endif
