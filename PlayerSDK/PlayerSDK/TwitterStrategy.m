//
//  TwitterStrategy.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/5/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "TwitterStrategy.h"

@implementation TwitterStrategy
- (NSString *)composeType {
    return SLServiceTypeTwitter;
}

//- (NSURL *)shareURL:(id<KPShareParams>)params {
//    if ([params shareLink] && [params shareLink].length > 10) {
//        NSString *requestString = [NSString stringWithFormat:@"https://twitter.com/share?url=%@", [params shareLink]];
//        requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//        return [NSURL URLWithString:requestString];
//    }
//    return nil;
//}
@end
