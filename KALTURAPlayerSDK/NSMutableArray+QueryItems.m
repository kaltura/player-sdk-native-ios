//
//  NSMutableArray+QueryItems.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 14/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "NSMutableArray+QueryItems.h"

@implementation NSMutableArray (QueryItems)
-(void)addQueryParam:(NSString*)key value:(NSString*)value {
    if (key.length && value.length) {
        [self addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }
}

@end
