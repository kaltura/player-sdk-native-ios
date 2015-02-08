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
#import "KPLog.h"
#import "NSMutableDictionary+AdSupport.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Utilities)
- (NSString *)appendParam:(NSDictionary *)param {
    if (param) {
        return [self stringByAppendingFormat:@"&%@=%@", param.allKeys[0], param.allValues[0]];
    }
    return nil;
}


- (Attribute)attributeEnumFromString {
    KPLogTrace(@"Enter");
    NSArray *attributes = @[@"src",
                            @"currentTime",
                            @"visible",
#if !(TARGET_IPHONE_SIMULATOR)
                            @"wvServerKey",
#endif
                            @"nativeAction",
                            @"doubleClickRequestAds"];
    KPLogTrace(@"Exit");
    return (Attribute)[attributes indexOfObject:self];
}

- (BOOL)isJSFrame {
    return [self hasPrefix:@"js-frame:"];
}

- (BOOL)isFrameURL {
    return [self rangeOfString: @"mwEmbedFrame"].location != NSNotFound
    || [self rangeOfString: @"embedIframeJs"].location != NSNotFound;
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

- (BOOL)isToggleFullScreen {
    return [self isEqualToString:KPlayerEventToggleFullScreen];
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

- (NSString *)md5 {
    const char *cStr = [self.sorted.absoluteString UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (int)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return  output;
}

- (NSString *)documentPath {
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return ([paths count] > 0) ? [paths.firstObject stringByAppendingPathComponent:self] : nil;
}

- (NSURL *)sorted {
    NSURL *url = [NSURL URLWithString:self];
    NSString *query = [url.query stringByRemovingPercentEncoding];
    NSMutableArray *params = [[NSMutableArray alloc] initWithArray:[query componentsSeparatedByString:@"&"]];
    if (params.count) {
        [params removeObjectAtIndex:0];
        params = [params sortedArrayUsingSelector:@selector(compare:)].mutableCopy;
    }
    NSString *sortedLink = [NSString stringWithFormat:@"%@://%@/%@?", url.scheme, url.host, url.path];
    for (NSString *param in params) {
        sortedLink = [sortedLink stringByAppendingFormat:@"%@&", param];
    }
    sortedLink = [[sortedLink substringToIndex:sortedLink.length - 1] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:sortedLink];
}

- (NSString *)addJSListener {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.addJsListener(\"%@\");", self];
}

- (NSString *)removeJSListener {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.removeJsListener(\"%@\");", self];
}

- (NSString *)evaluateWithID:(NSString *)ID {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.asyncEvaluate(\"%@\", \"%@\");", self, ID];
}

- (NSString *)sendNotificationWithBody:(NSString *)body {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.sendNotification(\"%@\" ,%@);", body, self];
}

- (NSString *)setKDPAttribute:(NSString *)attribute value:(NSString *)value {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.setKDPAttribute('%@','%@', %@);", self, attribute, value];
}

- (NSString *)triggerEvent:(NSString *)event {
    NSString* jsStringLog = [NSString stringWithFormat:@"trigger --> NativeBridge.videoPlayer.trigger(\"%@\", '%@')", self, event];
    KPLogInfo(@"%@", jsStringLog);
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.trigger('%@', '%@')", self, event];
}

- (NSString *)triggerJSON:(NSString *)json {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.trigger('%@', %@)", self, json];
}

- (NSDictionary *)nullVal {
    return @{self: @"(null)"};
}

- (NSDictionary *)adLoaded {
    return @{AdLoadedKey: self};
}

- (NSDictionary *)adClicked {
    return @{AdClickedKey: self};
}

- (NSDictionary *)adStart {
    return @{AdStartKey: self};
}

- (NSDictionary *)adCompleted {
    return @{AdCompletedKey: self};
}

- (NSDictionary *)adRemainingTimeChange {
    return @{AdRemainingTimeChangeKey: self};
}
@end
