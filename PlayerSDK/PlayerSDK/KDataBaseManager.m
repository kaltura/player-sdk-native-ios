//
//  KDataBaseManager.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 2/6/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KDataBaseManager.h"
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>
#import "NSString+Utilities.h"
#import "KCachedPages.h"

static NSString *CoreDataFileName = @"cachePath.cd";

@interface NSString (CoreData)

@end

@implementation NSString (CoreData)



@end

@interface KDataBaseManager()
@property (nonatomic, strong) UIManagedDocument *doc;
@end

@implementation KDataBaseManager

+ (KDataBaseManager *)shared {
    static id shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self.class new];
    });
    return shared;
}

- (void)initializeDocumentWithCompletion:(void(^)())completion {
    if (_doc) {
        completion();
    } else {
        NSURL *url = CoreDataFileName.documentPath;
        _doc = [[UIManagedDocument alloc] initWithFileURL:url];
        if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            [_doc saveToURL:url
           forSaveOperation:UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
              completion();
          }];
        }else if (_doc.documentState == UIDocumentStateClosed){
            [_doc openWithCompletionHandler:^(BOOL success) {
                completion();
            }];
        } else if (_doc.documentState == UIDocumentStateNormal) {
            completion();
        }
    }
}

- (void)contentOfURL:(NSString *)url
          completion:(void (^)(NSData *, NSError *))completion {
    [self initializeDocumentWithCompletion:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"KCachedPages"];
        request.predicate = [NSPredicate predicateWithFormat:@"hasedLink == %@", url.md5];
        NSError *error = nil;
        NSArray *matches = [_doc.managedObjectContext executeFetchRequest:request error:&error];
        if (matches.count == 1) {
            completion(((KCachedPages *)matches.lastObject).content, nil);
        } else if (error) {
            completion(nil, error);
        } else if (!matches.count) {
            
        }
        ///@todo handle case with more then One result
        ///@todo validate the content time
    }];
}


- (void)fetchContentAtURL:(NSString *)link completion:(void(^)(NSData *, NSError *error))completion {
    __weak KDataBaseManager *weakSelf = self;
    NSURL *url = [NSURL URLWithString:link];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError) {
                               if (data) {
                                   completion(data, nil);
                                   [weakSelf storeContent:data atURL:link];
                               } else if (connectionError) {
                                   completion(nil, connectionError);
                               }
                           }];
}

- (void)storeContent:(NSData *)content atURL:(NSString *)url {
    KCachedPages *cache = [NSEntityDescription insertNewObjectForEntityForName:@"KCachedPages"
                                                        inManagedObjectContext:_doc.managedObjectContext];
    cache.hasedLink = url.md5;
    cache.baseURL = url;
    cache.content = content;
    cache.storeTimeStamp = [NSDate date];
}
@end
