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

- (BOOL)isJSFrame {
    return [self hasPrefix:@"js-frame:"];
}

- (BOOL)isPlay {
    return [self isEqualToString:@"play"];
}

- (BOOL)isPause {
    return [self isEqualToString:@"pause"];
}

- (BOOL)isStop {
    return [self isEqualToString:@"stop"];
}

- (FunctionComponents)extractFunction {
    struct FunctionComponents function;
    function.name = nil;
    function.callBackID = -1;
    function.args = nil;
    NSArray *components = [self componentsSeparatedByString:@":"];
    if (components.count == 4) {
        function.name = (NSString*)[components objectAtIndex:1];
        function.callBackID = [((NSString*)[components objectAtIndex:2]) intValue];
        NSString *argsAsString = [(NSString*)[components objectAtIndex:3]
                                  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSError* error = nil;
        NSData* data = [argsAsString dataUsingEncoding:NSUTF8StringEncoding];
        function.args = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        function.error = error;
    }
    return function;
}

- (NSString *)addJSListener {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.addJsListener(\"%@\");", self];
}

- (NSString *)removeJSListener {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.removeJsListener(\"%@\");", self];
}

- (NSString *)asyncEvaluateWithListenerName:(NSString *)name {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.asyncEvaluate(\"%@\", \"%@\");", self, name];
}

- (NSString *)sendNotificationWithBody:(NSString *)body {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.sendNotification(\"%@\" ,%@);", self, body];
}

- (NSString *)setKDPAttribute:(NSString *)attribute value:(NSString *)value {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.setKDPAttribute('%@','%@', %@);", self, attribute, value];
}

- (NSString *)triggerEvent:(NSString *)event {
    NSString* jsStringLog = [NSString stringWithFormat:@"trigger --> NativeBridge.videoPlayer.trigger('%@', '%@')", self, event];
    NSLog(@"%@", jsStringLog);
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.trigger('%@', '%@')", self, event];
}
@end
