//
//  KPFlashvarObject.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPPlayerConfig.h"
#import "DeviceParamsHandler.h"



@interface KPPlayerConfig()

@property (nonatomic, copy, readonly) NSMutableDictionary *mutableFlashvarsDict;
@end

@implementation KPPlayerConfig
@synthesize mutableFlashvarsDict = _mutableFlashvarsDict;

- (NSMutableDictionary *)mutableFlashvarsDict {
    if (!_mutableFlashvarsDict) {
        _mutableFlashvarsDict = [NSMutableDictionary new];
    }
    return _mutableFlashvarsDict;
}

- (void)addConfigKey:(NSString *)key withValue:(NSString *)value; {
    if (key && key.length && value && value.length) {
        NSString *configKey = [NSString stringWithFormat:@"flashvars[%@]", key];
        self.mutableFlashvarsDict[configKey] = value;
    }
}

- (NSDictionary *)flashvarsDict {
    [self addDefaultFlags];
    return self.mutableFlashvarsDict.copy;
}

- (void)addDefaultFlags {
    [self addConfigKey:KPPlayerConfigNativeAdIdKey withValue:advertiserID()];
}

@end
