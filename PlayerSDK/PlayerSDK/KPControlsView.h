//
//  KPControlsView.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 4/12/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KArchiver.h"
#import "KPLog.h"
#import "NSString+Utilities.h"

@protocol KPControlsViewDelegate <NSObject>
@required
- (void)handleHtml5LibCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args;
@end

@protocol KPControlsView <NSObject>

@property (nonatomic, weak) id<KPControlsViewDelegate> controlsDelegate;
@property (nonatomic, copy) NSString *entryId;
//@property (nonatomic, assign, readonly) CGFloat videoHolderHeight;
@property (nonatomic) CGRect controlsFrame;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)loadRequest:(NSURLRequest *)request;

- (void)addEventListener:(NSString *)event;

- (void)removeEventListener:(NSString *)event;

- (void)evaluate:(NSString *)expression
      evaluateID:(NSString *)evaluateID;

- (void)sendNotification:(NSString *)notification
                withName:(NSString *)notificationName;

- (void)setKDPAttribute:(NSString *)pluginName
           propertyName:(NSString *)propertyName
                  value:(NSString *)value;

- (void)triggerEvent:(NSString *)event
           withValue:(NSString *)value;

- (void)triggerEvent:(NSString *)event withJSON:(NSString *)json;

- (void)updateLayout;

- (void)removeControls;

- (void)fetchvideoHolderHeight:(void(^)(CGFloat height))fetcher;

@end

@interface KPControlsView : UIView
+ (id<KPControlsView>)defaultControlsViewWithFrame:(CGRect)frame;
@end
