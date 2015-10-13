//
//  KDRMManager.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/24/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#if !(TARGET_IPHONE_SIMULATOR)

@interface KDRMManager : NSObject

@property (nonatomic, copy) NSString *DRMKey;
@property (nonatomic, copy) NSDictionary *DRMDict;

+ (void)DRMSource:(NSString *)src key:(NSDictionary *)dict completion:(void (^)(NSString *))completion;

@end

#endif