//
//  KDRMManager.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/24/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//
#if !(TARGET_IPHONE_SIMULATOR)
#import "KDRMManager.h"
#import "WViPhoneAPI.h"
#import "KPLog.h"

@interface KDRMManager()
@end

@implementation KDRMManager
@synthesize DRMKey, DRMDict;

- (void)setPlayerSource:(NSURL *)playerSource {
    [self.class DRMSource:playerSource.absoluteString
                      key:self.DRMDict
               completion:^(NSString *drmUrl) {
    }];
}

+ (void)DRMSource:(NSString *)src key:(NSDictionary *)dict completion:(void (^)(NSString *))completion {
    WV_Initialize(WVCallback, dict);
    [self performSelector:@selector(fetchDRMParams:) withObject:@[src, completion] afterDelay:0.1];
}

+ (void)fetchDRMParams:(NSArray *)params {
    NSMutableString *responseUrl = [NSMutableString string];
    WViOsApiStatus status = WV_Play(params.firstObject, responseUrl, nil);
    
    if (status == WViOsApiStatus_AlreadyPlaying) {
        WV_Stop();
        status = WV_Play(params.firstObject, responseUrl, nil);
    }
    
    KPLogDebug(@"widevine response url: %@", responseUrl);
    if ( status != WViOsApiStatus_OK ) {
        KPLogError(@"ERROR: %u",status);
        return;
    }
    ((void(^)(NSString *))params.lastObject)(responseUrl);
}

WViOsApiStatus WVCallback( WViOsApiEvent event, NSDictionary *attributes ) {
    KPLogTrace(@"Enter");
    KPLogInfo( @"callback %d %@\n", event, NSStringFromWViOsApiEvent( event ) );
    
    KPLogTrace(@"Exit");
    return WViOsApiStatus_OK;
}

@end

#endif
