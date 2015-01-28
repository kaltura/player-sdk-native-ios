//
//  KPIMAPlayerViewController.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 1/26/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "NSMutableDictionary+AdSupport.h"
#import "IMAAdsLoader.h"
#import "IMAAVPlayerContentPlayhead.h"

/**
 *  Supplies the playhead position for midroll ads
 */
@protocol KPIMAAdsPlayerDatasource <IMAContentPlayhead>

/// Supplies the height of the video holder dynamically
@property (nonatomic, assign, readonly) CGFloat adPlayerHeight;

@end

@interface KPIMAPlayerViewController : UIViewController <IMAAdsLoaderDelegate, IMAAdsManagerDelegate>


/**
 *  Initialize the IMA ads controller
 *
 *  @param UIViewController parentController conforms to KPIMAAdsPlayerDatasource for presenting the ads properly
 *
 *  @return KPIMAPlayerViewController IMA ads player
 */
- (instancetype)initWithParent:(UIViewController<KPIMAAdsPlayerDatasource> *)parentController;


/**
 *  Loads the ads into the IMA SDK
 *
 *  @param  NSString adLink contains the link to the XML file of the vast 
 *  @param  Block adListener which notifies the KPlayerViewController on the events of the ads
 */
- (void)loadIMAAd:(NSString *)adLink eventsListener:(void(^)(NSDictionary *adEventParams))adListener;


/// Releasing the memory of the IMA player
- (void)destroy;


@end
