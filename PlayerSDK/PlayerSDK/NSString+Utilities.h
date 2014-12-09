//
//  NSString+Utilities.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPViewControllerProtocols.h"

@interface NSString (Utilities)
- (NSString *)appendParam:(NSDictionary *)param;
@property (nonatomic, assign, readonly) Attribute attributeEnumFromString;
@end
