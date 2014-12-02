//
//  KPFlashvarObject.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *KPFlashvarNativeCallOutKey = @"nativeCallout";
static NSString *KPFlashvarChromecastKey = @"chromecast.plugin";

@interface KPPlayerConfig : NSObject
- (void)addFlashvar:(NSString *)key value:(NSString *)value;

@property (nonatomic, copy, readonly) NSArray *flashvarsArray;
@end
