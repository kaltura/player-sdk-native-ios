//
//  KPShareManager.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/5/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *NameKey = @"name";
static NSString *AppURLKey = @"appUrl";
static NSString *RedirectURL = @"redirectUrl";

/** Deals with any kind of share failure
 */
@interface KPShareError : NSObject
@property (nonatomic, strong) NSError *error;
@property (nonatomic, copy) NSString *errorTitle;
@property (nonatomic, copy) NSString *errorDescription;
@property (nonatomic, copy) NSString *errorButton;
@end

/** Share result
 */
typedef NS_ENUM(NSInteger, KPShareResults) {
    KPShareResultsSuccess,
    KPShareResultsFailed,
    KPShareResultsCancel
};

typedef void (^KPShareCompletionBlock)(KPShareResults result, KPShareError *shareError);

@protocol KPShareParams <NSObject>

@optional
@property (nonatomic, copy, readonly) NSString *shareTitle;
@property (nonatomic, copy, readonly) NSString *shareDescription;
@property (nonatomic, copy, readonly) NSString *shareLink;
@property (nonatomic, copy, readonly) NSString *shareIconName;
@property (nonatomic, copy, readonly) NSString *shareIconLink;
@property (nonatomic, copy, readonly) NSString *redirectURL;
@property (nonatomic, copy) NSString *facebookAppID;

@end

@protocol KPShareStratrgy <NSObject>

- (UIViewController *)share:(id<KPShareParams>)shareParams completion:(KPShareCompletionBlock)completion;

@end

@interface KPShareManager : NSObject
@property (nonatomic, unsafe_unretained) id<KPShareParams> datasource;
@property (nonatomic, strong) id<KPShareStratrgy> shareStrategyObject;

+ (KPShareManager *)shared;
- (UIViewController *)shareWithCompletion:(KPShareCompletionBlock)completion;

+ (void)fetchShareIcon:(NSString *)shareComposer completion:(void(^)(UIImage *icon, NSError *error))completion;
@end
