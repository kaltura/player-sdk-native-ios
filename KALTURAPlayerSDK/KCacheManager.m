//
//  KCacheManager.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/23/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KCacheManager.h"
#import "NSString+Utilities.h"
#import "KPLog.h"
#import "NSMutableDictionary+Cache.h"

NSString *const KalturaFolder = @"/KalturaFolder";

#define MB (1024*1024)
#define GB (MB*1024)

@interface KCacheManager ()
@property (nonatomic, readonly) NSString *cachePath;

@property (strong, nonatomic, readonly) NSBundle *bundle;
@property (strong, nonatomic, readonly) NSDictionary *cacheConditions;
@end

@interface NSString (Cache)
@property (nonatomic, readonly) BOOL deleteFile;
@property (nonatomic, readonly) NSString *pathForFile;
@end

@implementation KCacheManager
@synthesize cachePath = _cachePath;
@synthesize bundle = _bundle, cacheConditions = _cacheConditions, withDomain = _withDomain, subStrings = _subStrings;
+ (KCacheManager *)shared {
    static KCacheManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

// The SDK's bundle
- (NSBundle *)bundle {
    if (!_bundle) {
        _bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle]
                                           URLForResource:@"KALTURAPlayerSDKResources"
                                           withExtension:@"bundle"]];
    }
    return _bundle;
}


// Fetches the White list urls
- (NSDictionary *)cacheConditions {
    if (!_cacheConditions) {
        NSString *path = [self.bundle pathForResource:@"CachedStrings" ofType:@"plist"];
        _cacheConditions = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    return _cacheConditions;
}

// The url list which have to be checked by the domain first
- (NSDictionary *)withDomain {
    if (!_withDomain) {
        _withDomain = self.cacheConditions[@"withDomain"];
    }
    return _withDomain;
}


// The url list which should contain substring fron the White list
- (NSDictionary *)subStrings {
    if (!_subStrings) {
        _subStrings = self.cacheConditions[@"substrings"];
    }
    return _subStrings;
}


// Lazy initialization of the cache folder path
- (NSString *)cachePath {
    if (!_cachePath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = paths.firstObject; // Get documents folder
        _cachePath = [documentsDirectory stringByAppendingPathComponent:KalturaFolder];
    }
    return _cachePath;
}


// Calculates the size of the cached files
- (float)cachedSize {
    long long fileSize = 0;
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:CacheManager.cachePath error:nil];
    for (NSString *file in files) {
        fileSize += [[[NSFileManager defaultManager] attributesOfItemAtPath:file.pathForFile error:nil][NSFileSize] integerValue];
    }
    return (float)fileSize / MB;
}


// Returns sorted array of the content of the cache folder
- (NSArray *)files {
    NSMutableArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:self.cachePath error:nil].mutableCopy;
    [files sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSDate* d1 = [[NSFileManager defaultManager] attributesOfItemAtPath:obj1.pathForFile error:nil][NSFileModificationDate];
        NSDate* d2 = [[NSFileManager defaultManager] attributesOfItemAtPath:obj2.pathForFile error:nil][NSFileModificationDate];
        return [d1 compare:d2];
    }];
    return files;
}

@end



@implementation NSString (Cache)

// returns the full path for a file name
- (NSString *)pathForFile {
    return [CacheManager.cachePath stringByAppendingPathComponent:self];
}


// Fetches stored content from the cache directory by url converted to md5
- (NSDictionary *)cachedResponse {
    NSString *path = self.md5.pathForFile;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:path];
    [[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate: [NSDate date]} ofItemAtPath:path error:nil];
    NSDictionary *cached = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return cached;
}


/**
 Deletes file by name
 @return BOOL YES if the file deleted succesfully
 */
- (BOOL)deleteFile {
    NSString *path = self.pathForFile;
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (!error) {
            return YES;
        } else {
            KPLogError(@"%@", error);
        }
    }
    return NO;
}
@end


@implementation CachedURLParams

- (long long)freeDiskSpace {
    return [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize] longLongValue];
}

- (void)storeCacheResponse {
    float cachedSize = CacheManager.cachedSize;
    
    // if the cache size is too big, erases the least used files
    if (cachedSize > (float)[self freeDiskSpace] / MB || cachedSize > CacheManager.cacheSize) {
        float overflowSize = cachedSize - CacheManager.cacheSize + (float)self.data.length / MB;
        NSArray *files = CacheManager.files;
        for (NSString *fileName in files) {
            if (overflowSize > 0) {
                NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[CacheManager.cachePath stringByAppendingPathComponent:fileName]
                                                                                                error:nil];
                if (fileName.deleteFile) {
                    overflowSize -= [fileDictionary fileSize];
                }
            } else {
                break;
            }
        }
    }
    
    // Create Kaltura's folder if not already exists
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:CacheManager.cachePath isDirectory:&isDir];
    if (!exists) {
        [[NSFileManager defaultManager] createDirectoryAtPath:CacheManager.cachePath
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil];
    }
    
    // Store the page
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    attributes.encoding = self.response.textEncodingName;
    attributes.mimeType = self.response.MIMEType;
    attributes.data = self.data;
    [[NSFileManager defaultManager] createFileAtPath:self.url.absoluteString.md5.pathForFile
                                            contents:[NSKeyedArchiver archivedDataWithRootObject:attributes.copy]
                                          attributes:attributes.copy];
    
}

- (NSMutableData *)data {
    if (!_data) {
        _data = [[NSMutableData alloc] init];
    }
    return _data;
}



@end