//
//  NSString+Utilities.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

static NSString *SRC = @"src";
static NSString *CurrentTimeKey = @"currentTime";
static NSString *WVServerKey = @"wvServerKey";
static NSString *NativeActionKey = @"nativeAction";

#import "NSString+Utilities.h"

@implementation NSString (Utilities)
- (NSString *)appendParam:(NSDictionary *)param {
    if (param) {
        return [self stringByAppendingFormat:@"&%@=%@", param.allKeys[0], param.allValues[0]];
    }
    return nil;
}


- (Attribute)attributeEnumFromString {
    NSLog(@"attributeNameEnumFromString Enter");
    NSArray *attributes = @[@"src",
                            @"currentTime",
                            @"visible",
#if !(TARGET_IPHONE_SIMULATOR)
                            @"wvServerKey",
#endif
                            @"nativeAction"];
    
    NSLog(@"attributeNameEnumFromString Exit");
    return (Attribute)[attributes indexOfObject:self];
}
@end
