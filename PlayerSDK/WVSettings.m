//
//  WVSettings.m
//  Kaltura
//
//  Created by Eliza Sapir on 6/3/13.
//
//
#if !(TARGET_IPHONE_SIMULATOR)
#import "WVSettings.h"

@implementation WVSettings {
    NSString *playerSource;
}

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

- (void)playMovieFromUrl: (NSString *)videoUrlString {
    NSLog(@"playMovieFromUrl Enter");
    
    playerSource = videoUrlString;
    
    float wait = 0.1;
    
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval: wait
                                                              target: self
                                                            selector: @selector(playMovieFromUrlLater)
                                                            userInfo: nil
                                                             repeats: NO]
                              forMode:NSDefaultRunLoopMode];
    
    NSLog(@"playMovieFromUrl Exit");
}

- (void)playMovieFromUrlLater {
    NSLog(@"playMovieFromUrlLater Enter");
    
    NSMutableString *responseUrl = [NSMutableString string];
    
    NSArray *arr = [playerSource componentsSeparatedByString: @"?"];
    playerSource = [arr objectAtIndex: 0];
    
    WViOsApiStatus status = WV_Play(playerSource, responseUrl, 0);
    NSLog(@"widevine response url: %@", responseUrl);
    
    if ( status != WViOsApiStatus_OK ) {
        NSLog(@"ERROR: %u",status);
        
        return;
    }
    
    [ [NSNotificationCenter defaultCenter] postNotificationName: @"wvResponseUrlNotification"
                                                        object: nil
                                                      userInfo: @{@"response_url": responseUrl} ];
    
    NSLog(@"playMovieFromUrlLater Exit");
}
 
 

@end

#endif
