//
//  KArchiver.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 2/6/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KArchiver.h"
#import "NSString+Utilities.h"

static NSString *StorageName = @"cachePath.cd";

static NSString *ContentKey = @"content";
static NSString *BaseURLKey = @"baseUrl";
static NSString *TimeStampKey = @"timeStamp";

@interface NSDictionary (Archiver)
@property (nonatomic, copy, readonly) NSData *content;
@property (nonatomic, copy, readonly) NSURL *baseURL;
@property (nonatomic, copy, readonly) NSDate *timeStamp;
@end

@implementation NSDictionary (Archiver)
- (NSData *)content {
    return self[ContentKey];
}

- (NSURL *)baseURL {
    return self[BaseURLKey];
}


- (NSDate *)timeStamp {
    return self[TimeStampKey];
}



@end

@interface KArchiver()
@property (nonatomic, copy) NSMutableDictionary *cachedPages;
@end

@implementation KArchiver

+ (KArchiver *)shared {
    static id shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self.class new];
    });
    return shared;
}

- (NSMutableDictionary *)cachedPages {
    if (!_cachedPages) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:StorageName.documentPath]) {
            _cachedPages = [NSMutableDictionary new];
        } else {
            NSData *cachedData = [[NSFileManager defaultManager] contentsAtPath:StorageName.documentPath];
            _cachedPages = [NSKeyedUnarchiver unarchiveObjectWithData:cachedData];
        }
    }
    return _cachedPages;
}

- (void)contentOfURL:(NSString *)url
          completion:(void (^)(NSData *, NSError *))completion {
    if (self.cachedPages[url.md5]) {
        completion([self.cachedPages[url.md5] content], nil);
    } else {
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]
                                           queue:[NSOperationQueue new]
                               completionHandler:^(NSURLResponse *response,
                                                   NSData *data,
                                                   NSError *connectionError) {
                                   if (connectionError) {
                                       completion(nil, connectionError);
                                   } else if (data) {
                                       [self storeContent:data forURL:url];
                                       completion(data, nil);
                                   }
                               }];
    }
}


- (void)storeContent:(NSData *)content forURL:(NSString *)url {
    if (content && content.length && url && url.length) {
        self.cachedPages[url.md5] = @{ContentKey: content,
                                      BaseURLKey: url,
                                      TimeStampKey: [NSDate date]};
        [self synchronize];
    }
}

- (BOOL)isAlreadyLoaded:(NSString *)link {
    return self.cachedPages[link.md5] != nil;
}

- (void)synchronize {
    NSData *cachedData = [NSKeyedArchiver archivedDataWithRootObject:_cachedPages];
    [cachedData writeToFile:StorageName.documentPath atomically:YES];
    /// @todo handle write failure
}
@end
