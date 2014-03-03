//
//  WVSettings.m
//  Kaltura
//
//  Created by Eliza Sapir on 6/3/13.
//
//

#import "WVSettings.h"

@implementation WVSettings

static NSString *kPortalKey = @"kaltura";

-(WViOsApiStatus*)initializeWD: (NSString*) key {
    [self terminateWV];
    WViOsApiStatus *wvInitStatus = WV_Initialize( WVCallback, [self initializeWDDict: key] );
    
    return wvInitStatus;
    
}

WViOsApiStatus WVCallback( WViOsApiEvent event, NSDictionary *attributes ) {
    NSLog(@"WVCallback Enter");
    
    NSLog( @"callback %d %@\n", event, NSStringFromWViOsApiEvent( event ) );
    
    NSLog(@"WVCallback Enter");
    
    return WViOsApiStatus_OK;
}

-(NSDictionary*) initializeWDDict: (NSString*) key {

    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                key, WVDRMServerKey,
                                kPortalKey, WVPortalKey,
                                NULL];
    
    return dictionary;
}

- (void) terminateWV {
    WViOsApiStatus *wvTerminateStatus = WV_Terminate();
    
    if (wvTerminateStatus == WViOsApiStatus_OK) {
        NSLog(@"widevine was terminated");
    }
}

- (void) stopWV {
    WViOsApiStatus* wvStopStatus = WV_Stop();
    
    if (wvStopStatus == WViOsApiStatus_OK ) {
        NSLog(@"widevine was stopped");
    }
}

@end
