//
//  WVSettings.m
//  Kaltura
//
//  Created by Eliza Sapir on 6/3/13.
//
//
#if !(TARGET_IPHONE_SIMULATOR)
#import "WVSettings.h"
#import "KPLog.h"

@implementation WVSettings {
    NSString *playerSource;
}

static NSString *kPortalKey = @"kaltura";

-(WViOsApiStatus)initializeWD: (NSString*) key {
    [self terminateWV];
    WViOsApiStatus wvInitStatus = WV_Initialize( WVCallback, [self initializeWDDict: key] );
    
    return wvInitStatus;
    
}

WViOsApiStatus WVCallback( WViOsApiEvent event, NSDictionary *attributes ) {
    KPLogTrace(@"Enter");
    KPLogInfo( @"callback %d %@\n", event, NSStringFromWViOsApiEvent( event ) );
    
    KPLogTrace(@"Exit");
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
    WViOsApiStatus wvTerminateStatus = WV_Terminate();
    
    if (wvTerminateStatus == WViOsApiStatus_OK) {
        KPLogDebug(@"widevine was terminated");
    }
}

- (void) stopWV {
    WViOsApiStatus wvStopStatus = WV_Stop();
    
    if (wvStopStatus == WViOsApiStatus_OK ) {
        KPLogDebug(@"widevine was stopped");
    }
}

- (void)playMovieFromUrl: (NSString *)videoUrlString {
    KPLogTrace(@"Enter");
    playerSource = videoUrlString;
    
    float wait = 0.1;
    
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval: wait
                                                              target: self
                                                            selector: @selector(playMovieFromUrlLater)
                                                            userInfo: nil
                                                             repeats: NO]
                              forMode:NSDefaultRunLoopMode];
    KPLogTrace(@"Exit");
}

- (void)playMovieFromUrlLater {
    KPLogTrace(@"Enter");
    NSMutableString *responseUrl = [NSMutableString string];
    
    NSArray *arr = [playerSource componentsSeparatedByString: @"?"];
    playerSource = [arr objectAtIndex: 0];
    
    WViOsApiStatus status = WV_Play(playerSource, responseUrl, 0);
    KPLogDebug(@"widevine response url: %@", responseUrl);
    
    if ( status != WViOsApiStatus_OK ) {
        KPLogError(@"ERROR: %u",status);
        
        return;
    }
    
    [ [NSNotificationCenter defaultCenter] postNotificationName: @"wvResponseUrlNotification"
                                                        object: nil
                                                      userInfo: @{@"response_url": responseUrl} ];
    KPLogTrace(@"Exit");
}
 
 

@end

#endif
