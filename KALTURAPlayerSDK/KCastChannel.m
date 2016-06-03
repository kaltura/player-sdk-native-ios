//
//  KCastChannel.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 02/06/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//


#import "KCastChannel.h"
#import "KPLog.h"

@implementation KCastChannelParent

- (instancetype)initWithNamespace:(NSString *)protocolNamespace {
    self = [[NSClassFromString(@"GCKCastChannel") alloc] initWithNamespace:protocolNamespace];
    if (self) {
        return  self;
    }
    return nil;
}


@end

@implementation KCastChannel
- (instancetype)initWithNamespace:(NSString *)protocolNamespace {
    self = [super initWithNamespace:protocolNamespace];
    if (self) {
        return self;
    }
    return nil;
}

- (void)didReceiveTextMessage:(NSString *)message {
    
}
@end
