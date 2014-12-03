//
//  KPFlashvarObject.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPPlayerConfig.h"
#import "Utilities.h"

static NSString *KPPlayerConfigNativeAdIdKey = @"nativeAdId";

@interface KPPlayerConfig()

@property (nonatomic, copy, readonly) NSMutableArray *mutableFlashvarsArray;
@end

@implementation KPPlayerConfig
@synthesize mutableFlashvarsArray = _mutableFlashvarsArray;

- (NSMutableArray *)mutableFlashvarsArray {
    if (!_mutableFlashvarsArray) {
        _mutableFlashvarsArray = [NSMutableArray new];
    }
    return _mutableFlashvarsArray;
}

- (void)addConfigKey:(NSString *)key withValue:(NSString *)value; {
    if (key && value) {
        [self.mutableFlashvarsArray addObject:@{[NSString stringWithFormat:@"flashvars[%@]", key]: value}];
    }
}

- (NSArray *)flashvarsArray {
    [self addDefaultFlags];
    return self.mutableFlashvarsArray.copy;
}

- (void)addDefaultFlags {
    [self addConfigKey:KPPlayerConfigNativeAdIdKey withValue:advertiserID];
}

@end
