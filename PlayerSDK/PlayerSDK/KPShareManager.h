//
//  KPShareManager.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/5/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// Key for share provider value
static NSString *NameKey = @"name";

/// Key for share api Domain value
static NSString *RootURLKey = @"url";

/// Key for redirect URL value (use for determine that the share request has finished)
static NSString *RedirectURLKey = @"redirectUrl";

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
@property (nonatomic, copy, readonly) NSString *rootURL;
@property (nonatomic, copy, readonly) NSString *redirectURL;

@end

@protocol KPShareStratrgy <NSObject>

/** Performs post action according to the shareParams object
 *
 *  @param id<KPShareParams> contains all the paramters of the post
 *  @param KPShareCompletionBlock completion block callback when the post is done
 */
- (UIViewController *)share:(id<KPShareParams>)shareParams completion:(KPShareCompletionBlock)completion;

@end

@interface KPShareManager : NSObject

/// An object which contains all the parameters for creating a post
@property (nonatomic, unsafe_unretained) id<KPShareParams> datasource;

/// An object which conforms to the share strategy, represnts a share provider
@property (nonatomic, strong) id<KPShareStratrgy> shareStrategyObject;


/** Singleton instance
 *
 * @return KPShareManager instance
 */
+ (KPShareManager *)shared;


/** Perform post action by strategy pattern
 *
 *  @param KPShareCompletionBlock callback for post completion
 *
 *  @return UIViewController controller which reponsible on the post view
 */
- (UIViewController *)shareWithCompletion:(KPShareCompletionBlock)completion;


NSBundle *shareBundle();
UIImage *shareIcon(NSString *iconName);
@end
