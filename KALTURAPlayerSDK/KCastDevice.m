//
//  KCastDevice.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 31/05/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KCastDevice.h"
#import "KChromeCastWrapper.h"

@implementation KCastDevice
- (instancetype)initWithDevice:(id<KPGCDevice>)device {
    self = [super init];
    if (self) {
        _routerName = [device friendlyName];
        _routerId = [device deviceID];
    }
    return self;
}
@end
