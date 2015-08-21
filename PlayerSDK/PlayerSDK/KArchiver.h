//
//  KArchiver.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 2/6/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KArchiver : NSObject
+ (KArchiver *)shared;

- (void)contentOfURL:(NSString *)url
          completion:(void(^)(NSData *content, NSError *error))completion;

- (BOOL)isAlreadyLoaded:(NSString *)link;
@end
