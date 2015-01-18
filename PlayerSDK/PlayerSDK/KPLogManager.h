//
//  QLogManager.h
//  QadabraSDK
//
//  Created by Nissim Pardo on 3/25/14.
//  Copyright (c) 2014 Marimedia LTD. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KP_DEBUG_MODE				1

typedef NS_ENUM(NSInteger, KPLogLevel) {
    KPLogLevelAll		= 0,
	KPLogLevelTrace		= 10,
	KPLogLevelDebug		= 20,
	KPLogLevelInfo		= 30,
	KPLogLevelWarn		= 40,
	KPLogLevelError		= 50,
	KPLogLevelOff		= 60
};

// use the `QLogManager` methods to set the desired level of log filter
@interface KPLogManager : NSObject

// gets the current log filter level
+ (KPLogLevel)KPLogLevel;

// set the log filter level
+ (void)setKPLogLevel:(KPLogLevel)level;

+ (NSArray *)levelNames;
@end
