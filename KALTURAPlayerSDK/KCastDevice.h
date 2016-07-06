//
//  KCastDevice.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 31/05/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCastDevice : NSObject
@property (nonatomic, copy, readonly) NSString *routerName;
@property (nonatomic, copy, readonly) NSString *routerId;
@end
