//
//  NSString+Utilities.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

static NSString *SRC = @"src";
static NSString *CurrentTimeKey = @"currentTime";
static NSString *licenseUriKey = @"licenseUri";
static NSString *NativeActionKey = @"nativeAction";

NSString *const LocalContentId = @"localContentId";

#import "NSString+Utilities.h"
#import "KPLog.h"
#import "NSMutableDictionary+AdSupport.h"
#import <CommonCrypto/CommonDigest.h>
#import "DeviceParamsHandler.h"

@implementation NSString (Utilities)
- (NSString *)appendParam:(NSDictionary *)param {
    if (param) {
        return [self stringByAppendingFormat:@"&%@=%@", param.allKeys[0], param.allValues[0]];
    }
    return nil;
}

- (NSString *)appendVersion {
    NSString *versionFlashvar = [NSString stringWithFormat:@"&flashvars[nativeVersion]=%@", appVersion()];
    return [self stringByAppendingString:[versionFlashvar stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *)appendHover {
    NSString *versionFlashvar = @"&flashvars[controlBarContainer.hover]=true";
    return [self stringByAppendingString:[versionFlashvar stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *)appendIFrameEmbed {
    NSString *iFrameEmbed = @"&iframeembed=true";
    return [self stringByAppendingString:[iFrameEmbed stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *)appendIDFA:(NSString *)IDFA {
    NSString *IDFAFlashvar = [[NSString stringWithFormat:@"&flashvars[nativeAdId]=%@", IDFA] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [self stringByAppendingString:IDFAFlashvar];
}

- (NSString *)sqlite {
    return [self stringByAppendingString:@".sqlite-wal"];
}

- (NSString *)extractLocalContentId {
    NSArray *components = [self componentsSeparatedByString:@"#"];
    if (components.count == 2) {
        NSArray *hashTagParams = [components.lastObject componentsSeparatedByString:@"&"];
        for (NSString *hashTagParam in hashTagParams) {
            NSArray<NSString*> *param = [hashTagParam componentsSeparatedByString:@"="];
            if (param.count == 2 && [param.firstObject isEqualToString:LocalContentId]) {
                return param.lastObject.length > 0 ? param.lastObject : nil;
            }
        }
    }
    return nil;
}

- (Attribute)attributeEnumFromString {
    KPLogTrace(@"Enter");
    NSArray *attributes = @[@"src",
                            @"currentTime",
                            @"visible",
                            @"playerError",
                            @"licenseUri",
                            @"fpsCertificate",
                            @"nativeAction",
                            @"doubleClickRequestAds",
                            @"language",
                            @"captions",
                            @"audioTrackSelected",
                            @"chromecastAppId",
                            @"textTrackSelected"];
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

- (BOOL)isTimeUpdate {
    return [self isEqualToString:@"timeupdate"];
}

- (BOOL)isToggleFullScreen {
    return [self isEqualToString:KPlayerEventToggleFullScreen];
}

- (BOOL)isSeeked {
    return [self isEqualToString:@"seeked"];
}

- (BOOL)canPlay {
    return [self isEqualToString:@"canplay"];
}

- (BOOL)isDurationChanged {
    return [self isEqualToString:@"durationchange"];
}

- (BOOL)isMetadata {
    return [self isEqualToString:@"loadedmetadata"];
}

- (BOOL)isFrameKeypath {
    return [self isEqualToString:@"frame"];
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

- (NSString *)hexedMD5 {
    const char *cStr = self.UTF8String;
    unsigned char digest[16];
    CC_MD5( cStr, (int)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return  output;
}

- (BOOL)isWV {
    return [self.streamType isEqualToString:@"wvm"];
}

- (NSString *)mimeType {
    NSDictionary *mimeTypes = @{@"m3u8": @"application/vnd.apple.mpegurl",
                                @"mp4": @"video/mp4"};
    if (self.streamType) {
        return mimeTypes[self.streamType];
    }
    return nil;
}

- (NSArray *)castParams {
    NSString *test = @"|";
    NSArray *comps = [self componentsSeparatedByString:test];
    if (comps.count == 3) {
        NSArray *temp = [comps subarrayWithRange:(NSRange){1, 2}];
        return temp;
    }
    return nil;
}

- (NSString *)streamType {
    NSURLComponents *comp = [NSURLComponents componentsWithURL:[NSURL URLWithString:self]
                                       resolvingAgainstBaseURL:NO];
    NSArray *videoNameComp = [comp.path.lastPathComponent componentsSeparatedByString:@"."];
    return videoNameComp.lastObject;
}

- (NSString *)documentPath {
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return ([paths count] > 0) ? [paths.firstObject stringByAppendingPathComponent:self] : nil;
}

- (NSURL *)urlWithSortedParams {
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

- (NSDictionary *)nullVal {
    return @{self: @"(null)"};
}

- (NSDictionary *)adLoaded {
    return @{AdLoadedKey: self};
}

- (NSDictionary *)adClicked {
    return @{AdClickedKey: self};
}

- (NSDictionary *)adSkipped {
    return @{AdSkippeddKey: self};
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
