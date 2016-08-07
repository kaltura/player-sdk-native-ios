//
//  KCastProvider.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 31/05/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCastDevice.h"
#import "KCastMediaRemoteControl.h"

@class KCastProvider;

@protocol KCastProviderDelegate <NSObject>

@optional
- (void)castProvider:(KCastProvider *)provider devicesInRange:(BOOL)foundDevices;
- (void)castProvider:(KCastProvider *)provider didDeviceComeOnline:(KCastDevice *)device;
- (void)castProvider:(KCastProvider *)provider didDeviceGoOffline:(KCastDevice *)device;
- (void)didConnectToDevice:(KCastProvider *)provider;
- (void)didDisconnectFromDevice:(KCastProvider *)provider withError:(NSError *)error;
- (void)castProvider:(KCastProvider *)provider didFailToConnectToDevice:(NSError *)error;
- (void)castProvider:(KCastProvider *)provider didFailToDisconnectFromDevice:(NSError *)error;
- (void)castProvider:(KCastProvider *)provider mediaRemoteControlReady:(id<KCastMediaRemoteControl>)mediaRemoteControl;
@end

@interface KCastProvider : NSObject
- (instancetype)initWithCastChannel:(id)channel;
@property (nonatomic, readonly) id castChannel;
@property (nonatomic, getter=isCastButtonEnabled) BOOL castButtonEnabled;
@property (nonatomic) BOOL passiveScan;
@property (nonatomic, weak) id<KCastProviderDelegate> delegate;
@property (nonatomic, copy, readonly) NSArray<KCastDevice *> *devices;
@property (nonatomic, readonly) KCastDevice *selectedDevice;
@property (nonatomic, readonly) BOOL isConnected;
@property (nonatomic, weak, readonly) id<KCastMediaRemoteControl> mediaRemoteControl;

- (void)startScan:(NSString *)appID;
- (void)stopScan;
- (void)connectToDevice:(KCastDevice *)device;
- (void)disconnectFromDevice;
- (void)disconnectFromDeviceWithLeave;

@end
