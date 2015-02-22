//
//  NSDictionary+Strategy.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/23/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "NSDictionary+Strategy.h"

static NSString *ActionTypeKey = @"actionType";

static NSString *OpenURL = @"url";

static NSString *NetworkKeyPath = @"id";
static NSString *NetworkURLKeyPath = @"shareNetwork.template";
static NSString *NetworkRedirectURLKeyPath = @"shareNetwork.redirectUrl";
static NSString *SharedLinkKey = @"sharedLink";
static NSString *VideoNameKey = @"videoName";
static NSString *ThumbnailKey = @"thumbnail";


@implementation NSDictionary (Strategy)
- (NSString *)videoName {
    return self[VideoNameKey];
}

- (NSString *)shareLink {
    return self[SharedLinkKey];
}

- (NSString *)thumbnailLink {
    return self[ThumbnailKey];
}

- (NSString *)networkURL {
    return [self valueForKeyPath:NetworkURLKeyPath];
}

- (NSArray *)redirectURLs {
    NSString *urlsString = [self valueForKeyPath:NetworkRedirectURLKeyPath];
    NSArray *urls = [urlsString componentsSeparatedByString:@","];
    if (urlsString.length && !urls.count) {
        return @[urlsString];
    }
    return urls;
}

- (Class)networkStrategyClass {
    NSString *strategyName = [[self valueForKeyPath:NetworkKeyPath] stringByAppendingString:@"Strategy"];
    return NSClassFromString(strategyName);
}

- (NSString *)actionType {
    return self[ActionTypeKey];
}

- (NSURL *)openURL {
    return [NSURL URLWithString:self[OpenURL]];
}
@end
