//
//  GoogleCastProvider.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 18/09/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "GoogleCastProvider.h"
#import "KPLog.h"

@interface GoogleCastProvider () <GCKSessionManagerListener> {
   GCKSessionManager *_sessionManager;
}

@property (nonatomic, strong)  GCKMediaControlChannel *mediaControlChannel;

@end

@implementation GoogleCastProvider

- (void)sessionManager:(GCKSessionManager *)sessionManager didStartCastSession:(GCKCastSession *)session {
    // TODO:: Custom Channel Registration (https://developers.google.com/cast/v2/ios_migrate_sender)
}

- (void)sessionManager:(GCKSessionManager *)sessionManager didFailToStartSession:(GCKSession *)session withError:(NSError *)error {
    
}

@end
