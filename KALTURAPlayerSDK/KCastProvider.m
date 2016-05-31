//
//  KCastProvider.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 31/05/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KCastProvider.h"
#import "KChromeCastWrapper.h"
#import "KPLog.h"

@interface KCastDevice ()
- (instancetype)initWithDevice:(id<KPGCDevice>)device;
@end

@protocol FilterCriteria <NSObject>

- (id)criteriaForAvailableApplicationWithID:(NSString *)appId;

@end

@interface KCastProvider () <KPGCDeviceScannerListener>
@property (nonatomic, strong) id<KPGCDeviceScanner> deviceScanner;
@property (nonatomic, strong) id<KPGCDeviceManager> deviceManager;
@property (nonatomic, copy) NSString *appID;
@end

@implementation KCastProvider

- (instancetype)init {
    if (!NSClassFromString(@"GCKDeviceScanner")) {
        KPLogWarn(@"GoogleCast is not linked");
        return nil;
    }
    self = [super init];
    if (self) {
        return self;
    }
    return nil;
}

- (void)setPassiveScan:(BOOL)passiveScan {
    _passiveScan = passiveScan;
    _deviceScanner.passiveScan = passiveScan;
}

- (void)startScan:(NSString *)appID {
    _appID = appID;
    // Establish filter criteria.
    id<FilterCriteria> filterCriteria = [NSClassFromString(@"GCKFilterCriteria") criteriaForAvailableApplicationWithID:appID];
    
    // Initialize device scanner.
    self.deviceScanner = [[NSClassFromString(@"GCKDeviceScanner") alloc] initWithFilterCriteria:filterCriteria];
    [_deviceScanner addListener:self];
    [_deviceScanner startScan];
    _deviceScanner.passiveScan = _passiveScan;
}

- (void)stopScan {
    [_deviceScanner stopScan];
}

- (void)connectToDevice:(KCastDevice *)device {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deviceID == %@", device.routerId];
    NSArray<id<KPGCDevice>> *matches = [_deviceScanner.devices filteredArrayUsingPredicate:predicate];
    if (matches.count) {
        if (!_deviceManager) {
            _deviceManager = [[NSClassFromString(@"GCKDeviceManager") alloc] initWithDevice:matches.firstObject
                                                                          clientPackageName:[NSBundle mainBundle].bundleIdentifier];
            _deviceManager.delegate = self;
            [_deviceManager connect];
        }
    }
}

- (void)disconnectFromDevice {
    [_deviceManager disconnect];
}

#pragma mark KPGCDeviceScannerListener
- (void)deviceDidComeOnline:(id<KPGCDevice>)device {
    if ([_delegate respondsToSelector:@selector(castProvider:didDeviceComeOnline:)]) {
        [_delegate castProvider:self didDeviceComeOnline:[[KCastDevice alloc] initWithDevice:device]];
    }
}

- (void)deviceDidGoOffline:(id<KPGCDevice>)device {
    if ([_delegate respondsToSelector:@selector(castProvider:didDeviceGoOffline:)]) {
        [_delegate castProvider:self didDeviceGoOffline:[[KCastDevice alloc] initWithDevice:device]];
    }
}

- (void)deviceManagerDidConnect:(id<KPGCDeviceManager>)deviceManager {
    if ([_delegate respondsToSelector:@selector(didConnectToDevice:)]) {
        [_delegate didConnectToDevice:self];
    }
    
    
    
//    // Launch application after getting connected.
//    [_deviceManager launchApplication:kReceiverAppID];
}
@end
