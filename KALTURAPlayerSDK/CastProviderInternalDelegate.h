//
//  CastProviderInternalDelegate.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 05/06/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KChromeCastWrapper.h"

@protocol CastProviderInternalDelegate <NSObject>
- (void)startCasting:(id<KCastMediaRemoteControl>)castPlayer;
- (void)updateCastState:(NSString *)state;
- (void)stopCasting;
@end
