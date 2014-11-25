//
//  KPShareManager.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 11/5/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


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


/// Share action call back
typedef void (^KPShareCompletionBlock)(KPShareResults result, KPShareError *shareError);


/// All the parameters for submitting share action
@protocol KPShareParams <NSObject>

@optional

/// Contains the video name according to the meta data of the page
@property (nonatomic, copy, readonly) NSString *videoName;

/// The link to the video, played by Kaltura player
@property (nonatomic, copy, readonly) NSString *shareLink;

/// The link for the first frame of the video
@property (nonatomic, copy, readonly) NSString *thumbnailLink;

/// Share API of the selected network
@property (nonatomic, copy, readonly) NSString *networkURL;

/// Redirect URIs: cancel, finished, fail
@property (nonatomic, copy, readonly) NSArray *redirectURLs;

/// Generates the strategy class by the network name
@property (nonatomic, assign, readonly) Class networkStrategyClass;
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
@property (nonatomic, strong) id<KPShareParams> datasource;



/** Perform post action by strategy pattern
 *
 *  @param KPShareCompletionBlock callback for post completion
 *
 *  @return UIViewController controller which reponsible on the post view
 */
- (UIViewController *)shareWithCompletion:(KPShareCompletionBlock)completion;

@end
