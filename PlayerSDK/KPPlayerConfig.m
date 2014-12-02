//
//  KPFlashvarObject.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPPlayerConfig.h"
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

- (void)addFlashvar:(NSString *)key value:(NSString *)value {
    if (key && value) {
        [self.mutableFlashvarsArray addObject:@{key: [NSString stringWithFormat:@"flashvars[%@]", value]}];
    }
}

- (NSArray *)flashvarsArray {
    return self.mutableFlashvarsArray.copy;
}
@end
