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

@interface KPShareManager()

/// An object which conforms to the share strategy, represnts a share provider
@property (nonatomic, strong) id<KPShareStratrgy> strategy;
@end

@implementation KPShareManager

- (UIViewController *)shareWithCompletion:(KPShareCompletionBlock)completion {
    // Check if _datasource initialized
    if (_datasource && [_datasource respondsToSelector:@selector(networkStrategyClass)]) {
        
        // Creating a strategy object according to the user selection
        self.strategy = [[_datasource networkStrategyClass] new];
        
        // Creating the share viewController
        return [self.strategy share:_datasource completion:completion];
    }
    return nil;
}

- (void)dealloc {
    
}

@end
