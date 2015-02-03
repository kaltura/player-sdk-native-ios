//
//  QLogManager.m
//  QadabraSDK
//
//  Created by Nissim Pardo on 3/25/14.
//  Copyright (c) 2014 Marimedia LTD. All rights reserved.
//

#import "KPLogManager.h"

static KPLogLevel KPLOG_LEVEL = KPLogLevelWarn;

@implementation KPLogManager
+ (KPLogLevel)KPLogLevel {
    @synchronized(self) {
        return KPLOG_LEVEL;
    }
	
}

+ (void)setKPLogLevel:(KPLogLevel)level {
    @synchronized(self) {
        KPLOG_LEVEL = level;
    }
}

+ (NSArray *)levelNames {
    @synchronized(self) {
        return @[@"All", @"Trace", @"Debug", @"Info", @"Warn", @"Error"];
    }
}
@end
