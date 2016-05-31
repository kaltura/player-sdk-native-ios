//
//  KCastProvider.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 31/05/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCastDevice.h"

@class KCastProvider;
@protocol KCastProviderDelegate <NSObject>

- (void)castProvider:(KCastProvider *)provider didDeviceComeOnline:(KCastDevice *)device;
- (void)castProvider:(KCastProvider *)provider didDeviceGoOffline:(KCastDevice *)device;
- (void)didConnectToDevice:(KCastProvider *)provider;
- (void)didDisconnectFromDevice:(KCastProvider *)provider;
- (void)castProvider:(KCastProvider *)provider didFailToConnectToDevice:(NSError *)error;
- (void)castProvider:(KCastProvider *)provider didFailToDisconnectFromDevice:(NSError *)error;

@end

@interface KCastProvider : NSObject

@property (nonatomic, getter=isCastButtonEnabled) BOOL castButtonEnabled;
@property (nonatomic) BOOL passiveScan;
@property (nonatomic, weak) id<KCastProviderDelegate> delegate;

- (void)startScan:(NSString *)appID;
- (void)stopScan;
- (void)connectToDevice:(KCastDevice *)device;
- (void)disconnectFromDevice;

@end
