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

@interface NSMutableDictionary (Archiver)
@property (nonatomic, copy) NSData *content;
@property (nonatomic, copy) NSURL *baseURL;
@property (nonatomic, copy) NSDate *timeStamp;
@end

@implementation NSMutableDictionary (Archiver)
- (NSData *)content {
    return self[ContentKey];
}

- (void)setContent:(NSData *)content {
    if (content && content.length) {
        self[ContentKey] = content;
    }
}

- (NSURL *)baseURL {
    return self[BaseURLKey];
}

- (void)setBaseURL:(NSURL *)baseURL {
    if (baseURL && baseURL.absoluteString.length) {
        self[BaseURLKey] = baseURL;
    }
}

- (NSDate *)timeStamp {
    return self[TimeStampKey];
}

- (void)setTimeStamp:(NSDate *)timeStamp {
    if (timeStamp) {
        self[TimeStampKey] = timeStamp;
    }
}


@end

@interface KArchiver()
@property (nonatomic, copy) NSMutableDictionary *cachedPages;
@end

@implementation KArchiver
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
    if ([self.cachedPages[url.md5] content]) {
        completion([self.cachedPages[url.md5] content], nil);
    } else {
        NSURL *pageUrl = [NSURL URLWithString:url];
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:pageUrl]
                                           queue:[NSOperationQueue new]
                               completionHandler:^(NSURLResponse *response,
                                                   NSData *data,
                                                   NSError *connectionError) {
                                   if (connectionError) {
                                       completion(nil, connectionError);
                                   } else if (data) {
                                       completion(data, nil);
                                       
                                   }
                               }];
    }
}

- (void)storeContent:(NSData *)content forURL:(NSString *)url {
    self
}

- (void)synchronize {
    NSData *cachedData = [NSKeyedArchiver archivedDataWithRootObject:_cachedPages];
    [cachedData writeToFile:StorageName.documentPath atomically:YES];
    /// @todo handle write failure
}
@end
