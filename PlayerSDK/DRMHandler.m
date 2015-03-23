//
//  DRMHandler.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/19/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "DRMHandler.h"
#import "WViPhoneAPI.h"
#import "KPLog.h"

static NSString *kPortalKey = @"kaltura";

@implementation DRMHandler
+ (void)DRMSource:(NSString *)src key:(NSString *)key completion:(void (^)(NSString *))completion {
    WV_Initialize(WVCallback, @{WVDRMServerKey: key, WVPortalKey: kPortalKey});
    [self performSelector:@selector(fetchDRMParams:) withObject:@[src, completion] afterDelay:0.1];
}

+ (void)fetchDRMParams:(NSArray *)params {
    NSMutableString *responseUrl = [NSMutableString string];
    WViOsApiStatus status = WV_Play(params[0], responseUrl, 0);
    KPLogDebug(@"widevine response url: %@", responseUrl);
    if ( status != WViOsApiStatus_OK ) {
        KPLogError(@"ERROR: %u",status);
        return;
    }
    ((void(^)(NSString *))params[1])(responseUrl);
}

+ (void)fetchDRMSource:(NSString *)src key:(NSString *)key completion:(void(^)(NSString *))completion {
    
}

WViOsApiStatus WVCallback( WViOsApiEvent event, NSDictionary *attributes ) {
    KPLogTrace(@"Enter");
    KPLogInfo( @"callback %d %@\n", event, NSStringFromWViOsApiEvent( event ) );
    
    KPLogTrace(@"Exit");
    return WViOsApiStatus_OK;
}


@end
