//
//  DRMHandler.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/19/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DRMHandler : NSObject
+ (void)DRMSource:(NSString *)src key:(NSString *)key completion:(void(^)(NSString *DRMLink))completion;
@end
