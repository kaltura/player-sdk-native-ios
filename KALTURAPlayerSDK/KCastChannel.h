//
//  KCastChannel.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 02/06/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KChromeCastWrapper.h"



@interface KCastChannelParent : NSObject <KPGCCastChannel>

@end

@interface KCastChannel : KCastChannelParent

@end