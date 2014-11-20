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


NSBundle *shareBundle() {
    return [NSBundle bundleWithURL:[[NSBundle mainBundle]
                                    URLForResource:@"Test"
                                    withExtension:@"bundle"]];
}

UIImage *shareIcon(NSString *iconName) {
    NSString *imagePath = [NSString stringWithFormat:@"Test.bundle/%@", iconName];
    return [UIImage imageNamed:imagePath];
}
@end
