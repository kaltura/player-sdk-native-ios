//
//  KPShareManager.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/5/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPShareManager.h"

@implementation KPShareError
@end

@implementation KPShareManager
+ (KPShareManager *)shared {
    static KPShareManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (UIViewController *)shareWithCompletion:(KPShareCompletionBlock)completion {
    if (_shareStrategyObject && [_shareStrategyObject respondsToSelector:@selector(share:completion:)]) {
        return [_shareStrategyObject share:_datasource completion:completion];
    }
    return nil;
}

+ (void)fetchShareIcon:(NSString *)shareComposer completion:(void (^)(UIImage *, NSError *))completion {
    NSString *rootURL = @"https://sites.google.com/site/kalturaimages/shareicons/";
    rootURL = [rootURL stringByAppendingFormat:@"%@.png", shareComposer];
    NSURL *url = [NSURL URLWithString:rootURL];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue new]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError) {
                                   completion(nil, connectionError);
                               } else if (data) {
                                   UIImage *img = [UIImage imageWithData:data];
                                   if ([img isKindOfClass:[UIImage class]]) {
                                       completion(img, nil);
                                   } else {
                                       completion(nil, [NSError errorWithDomain:@"Image not valid"
                                                                           code:10000
                                                                       userInfo:nil]);
                                   }
                               }
                           }];
}
@end
