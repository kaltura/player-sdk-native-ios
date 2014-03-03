//
//  WVSettings.h
//  Kaltura
//
//  Created by Eliza Sapir on 6/3/13.
//
//

#import <Foundation/Foundation.h>
#import "WViPhoneAPI.h"

@interface WVSettings : NSObject

-(WViOsApiStatus*)initializeWD: (NSString*) key;
- (void) stopWV;

@end
