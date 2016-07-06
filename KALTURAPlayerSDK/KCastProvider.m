//
//  KCastProvider.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 31/05/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KCastProvider.h"
#import "KPLog.h"
#import "KChromeCastWrapper.h"
#import "CastProviderInternalDelegate.h"
#import "NSString+Utilities.h"


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
@property (nonatomic, strong) id castChannel;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, weak) id<CastProviderInternalDelegate> internalDelegate;
@property (nonatomic, copy) NSString *sessionID;
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

- (instancetype)initWithCastChannel:(id)channel {
    self = [self init];
    if (self) {
        _castChannel = channel;
        [_castChannel setDelegate:self];
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
    self.deviceScanner = [[NSClassFromString(@"GCKDeviceScanner") alloc] init];
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
    [_internalDelegate stopCasting];
    [_deviceManager disconnect];
}

- (void)disconnectFromDeviceWithLeave {
    [_internalDelegate stopCasting];
    [_deviceManager stopApplicationWithSessionID:_sessionID];
    [_deviceManager removeChannel:_castChannel];
    [_deviceManager removeChannel:_mediaControlChannel];
    [_deviceManager disconnect];
    _deviceManager.delegate = nil;
    _deviceManager = nil;

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
    
    
    
    // Launch application after getting connected.
    id launchOptions = [[NSClassFromString(@"GCKLaunchOptions") alloc] initWithRelaunchIfRunning:YES];
    [_deviceManager launchApplication:_appID withLaunchOptions:launchOptions];
}

- (void)deviceManager:(id<KPGCDeviceManager>)deviceManager
didConnectToCastApplication:(id<KPGCMediaMetadata>)applicationMetadata
            sessionID:(NSString *)sessionID
  launchedApplication:(BOOL)launchedApplication {
    _sessionID = sessionID;
    if (!_mediaControlChannel) {
        _mediaControlChannel = [NSClassFromString(@"GCKMediaControlChannel") new];
        _mediaControlChannel.delegate = self;
        [_deviceManager addChannel:_mediaControlChannel];
        [_mediaControlChannel requestStatus];
        _castChannel = [[NSClassFromString(@"GCKGenericChannel") alloc] initWithNamespace:@"urn:x-cast:com.kaltura.cast.player"];
        [_castChannel setDelegate:self];
        [deviceManager addChannel:_castChannel];
        [_castChannel sendTextMessage:@"{\"type\":\"show\",\"target\":\"logo\"}"];
    }
    [_internalDelegate updateCastState:@"chromecastDeviceConnected"];
}

- (void)castChannel:(id)channel
didReceiveTextMessage:(NSString *)message
      withNamespace:(NSString *)protocolNamespace {
    if ([message hasPrefix:@"readyForMedia"]) {
        [_castChannel sendTextMessage:@"{\"type\":\"hide\",\"target\":\"logo\"}"];
        NSArray *castParams = message.castParams;
        if (castParams) {
            _mediaControlChannel.delegate = _internalDelegate;
            id<KPGCMediaInformation> mediaInformation = [[NSClassFromString(@"GCKMediaInformation") alloc] initWithContentID:castParams.firstObject
                                                                                                                  streamType:0
                                                                                                                 contentType:castParams.lastObject
                                                                                                                    metadata:nil
                                                                                                              streamDuration:0
                                                                                                                  customData:nil];
            [_mediaControlChannel loadMedia:mediaInformation autoplay:NO playPosition:0];
        }
        [_internalDelegate startCasting:_mediaControlChannel];
    }
}

- (void)castChannelDidConnect:(id)channel {
    if ([_delegate respondsToSelector:@selector(didConnectToDevice:)]) {
        [_delegate didConnectToDevice:self];
    }
}

- (void)castChannelDidDisconnect:(id)channel {
    if ([_delegate respondsToSelector:@selector(didDisconnectFromDevice:)]) {
        [_delegate didDisconnectFromDevice:self];
    }
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
