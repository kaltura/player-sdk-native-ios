//
//  NSBundle+Kaltura.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 25/11/2015.
//  Copyright © 2015 Kaltura. All rights reserved.
//

#import "NSBundle+Kaltura.h"

@implementation NSBundle (Kaltura)

- (BOOL)isAudioBackgroundModesEnabled {
    NSArray *backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
    
    return [backgroundModes containsObject:@"audio"];
}


@end
