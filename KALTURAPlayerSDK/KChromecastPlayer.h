//
//  KChromecastPlayer.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 02/06/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KChromeCastWrapper.h"
#import "KCastMediaRemoteControl.h"

@interface KChromecastPlayer : NSObject <KCastMediaRemoteControl >
- (instancetype)initWithMediaChannel:(id<KPGCMediaControlChannel>)mediaChannel andCastParams:(NSArray *)castParams;
@property (nonatomic, copy) NSString *mediaSrc;
@end
