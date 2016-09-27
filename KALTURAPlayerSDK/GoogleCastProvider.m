//
//  GoogleCastProvider.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 18/09/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "GoogleCastProvider.h"
#import "KPLog.h"

@interface GoogleCastProvider () <GCKSessionManagerListener, GCKGenericChannelDelegate> {
}

@property (nonatomic, strong)  GCKGenericChannel *castChannel;
@property (nonatomic, strong)  GCKCastSession *session;

@end

@implementation GoogleCastProvider


- (instancetype)init {
    self = [super init];
    
    if (self) {
        [[GCKCastContext sharedInstance].sessionManager addListener:self];
    }
    
    return self;
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
   didStartCastSession:(GCKCastSession *)session {
    if (!_castChannel) {
        _castChannel = [[GCKGenericChannel alloc] initWithNamespace:@"urn:x-cast:com.kaltura.cast.player"];
        [_castChannel setDelegate:self];
        _session = session;
        [_session addChannel:_castChannel];
        [self sendTextMessage:@"{\"type\":\"show\",\"target\":\"logo\"}"];
        //        [_internalDelegate updateCastState:@"chromecastDeviceConnected"];
    }
}

- (BOOL)isConnected {
    return YES;
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
     didEndCastSession:(GCKCastSession *)session
             withError:(NSError * GCK_NULLABLE_TYPE)error {
    if (error) {
        
        KPLogError(@"JS Error %@", error.description);
    }
    
    [self sendTextMessage:@"{\"type\":\"hide\",\"target\":\"logo\"}"];
    [session removeChannel:_castChannel];
    _castChannel = nil;
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
       didStartSession:(GCKSession *)session {
    NSLog(@"MediaViewController: sessionManager didStartSession %@", session);

}

- (void)castChannelDidConnect:(GCKGenericChannel *)channel {
    NSLog(@"");
}

- (void)sessionManager:(GCKSessionManager *)sessionManager
 didFailToStartSession:(GCKSession *)session withError:(NSError *)error {
    /// TODO:: error
    [self sendTextMessage:@"{\"type\":\"hide\",\"target\":\"logo\"}"];
    // remove _cast channel
    
}

- (void)castChannel:(GCKGenericChannel *)channel
didReceiveTextMessage:(NSString *)message
      withNamespace:(NSString *)protocolNamespace {
    NSLog(@"didReceiveTextMessage::");

}

- (BOOL)sendTextMessage:(NSString *)message {
    NSLog(@"sendmessage::: %@", message);
    if (_castChannel) {
        return [_castChannel sendTextMessage:message];
    }
    
    return NO;
}
@end
