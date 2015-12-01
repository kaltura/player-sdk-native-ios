//
//  NSDictionary+Cache.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/23/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "NSDictionary+Cache.h"

@implementation NSDictionary (Cache)
- (NSString *)path {
    return self[@"path"];
}

- (NSData *)data {
    return self[@"data"];
}
- (NSString *)encoding {
    return self[@"encoding"];
}

- (NSString *)mimeType {
    return self[@"mimeType"];
}

- (NSDate *)timestamp {
    return self[@"timeStamp"];
}

- (NSString *)url {
    return self[@"url"];
}

- (NSDate *)lastUsed {
    return self[@"lastUsed"];
}
@end
