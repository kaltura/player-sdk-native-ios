//
//  GooglePlusStrategy.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/18/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "GoogleplusStrategy.h"

@implementation GoogleplusStrategy
- (UIViewController *)share:(id<KPShareParams>)shareParams completion:(KPShareCompletionBlock)completion {
    return [self shareWithBrowser:shareParams completion:completion];
}
@end
