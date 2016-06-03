//
//  KCastProvider.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 31/05/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KCastProvider.h"
#import "KCastChannel.h"
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
@property (nonatomic, strong) id<KPGCMediaControlChannel> mediaControlChannel;
@property (nonatomic, strong) KCastChannel *castChannel;
@property (nonatomic, copy) NSString *appID;
@end

@implementation KCastProvider
@synthesize selectedDevice = _selectedDevice, isConnected = _isConnected;

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

- (NSArray<KCastDevice *> *)devices {
    if (_deviceScanner.devices.count) {
        NSMutableArray *convertedDevices = [NSMutableArray new];
        for (id<KPGCDevice> device in _deviceScanner.devices) {
            [convertedDevices addObject:[[KCastDevice alloc] initWithDevice:device]];
        }
        return convertedDevices.copy;
    }
    return nil;
}

- (void)updateCastButton {
    if ([_delegate respondsToSelector:@selector(castProvider:devicesInRange:)]) {
        [_delegate castProvider:self devicesInRange:_deviceScanner.devices.count];
    }
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
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSString *appIdentifier = [info objectForKey:@"CFBundleIdentifier"];
        _deviceManager = [[NSClassFromString(@"GCKDeviceManager") alloc] initWithDevice:matches.firstObject
                                                                      clientPackageName:appIdentifier];
        _deviceManager.delegate = self;
        [_deviceManager connect];
    }
}

- (void)disconnectFromDevice {
    id<KPGCDevice> selectedDevice = _deviceManager.device;
    [_deviceManager stopApplicationWithSessionID:_appID];
    [_deviceManager disconnect];
    selectedDevice = nil;
    _deviceManager.delegate = nil;
    _deviceManager = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
}

#pragma mark KPGCDeviceScannerListener
- (void)deviceDidComeOnline:(id<KPGCDevice>)device {
    [self updateCastButton];
    if ([_delegate respondsToSelector:@selector(castProvider:didDeviceComeOnline:)]) {
        [_delegate castProvider:self didDeviceComeOnline:[[KCastDevice alloc] initWithDevice:device]];
    }
}

- (void)deviceDidGoOffline:(id<KPGCDevice>)device {
    [self updateCastButton];
    if ([_delegate respondsToSelector:@selector(castProvider:didDeviceGoOffline:)]) {
        [_delegate castProvider:self didDeviceGoOffline:[[KCastDevice alloc] initWithDevice:device]];
    }
}

- (void)deviceManagerDidConnect:(id<KPGCDeviceManager>)deviceManager {
    _selectedDevice = [[KCastDevice alloc] initWithDevice:deviceManager.device];
    _isConnected = YES;
    if ([_delegate respondsToSelector:@selector(didConnectToDevice:)]) {
        [_delegate didConnectToDevice:self];
    }
    
    
    
//    // Launch application after getting connected.
    [_deviceManager launchApplication:_appID];
}

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager
didConnectToCastApplication:(id<KPGCMediaMetadata>)applicationMetadata
            sessionID:(NSString *)sessionID
  launchedApplication:(BOOL)launchedApplication {
    _mediaControlChannel = [NSClassFromString(@"GCKMediaControlChannel") new];
    _mediaControlChannel.delegate = self;
    [_deviceManager addChannel:_mediaControlChannel];
    [_mediaControlChannel requestStatus];
    _castChannel = [[KCastChannel alloc] initWithNamespace:@"urn:x-cast:com.kaltura.cast.player"];
    [_castChannel addObserver:self forKeyPath:@"didReceiveTextMessage:" options:0 context:nil];
    [deviceManager addChannel:_castChannel];
    [_castChannel sendTextMessage:@"{\"type\":\"show\",\"target\":\"logo\"}"];
}

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager
didReceiveStatusForApplication:(id<KPGCMediaMetadata>)applicationMetadata {
//    self.applicationMetadata = applicationMetadata;
}

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager didDisconnectWithError:(NSError *)error {
    _isConnected = NO;
}

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager didFailToStopApplicationWithError:(NSError *)error {
    
}

@end
