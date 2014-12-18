//
//  KPPlayerDatasource.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPViewControllerProtocols.h"


@interface KPPlayerDatasourceHandler : NSObject

/** Converts datasource into video request
 *
 *  @param  id<KPViewControllerDatasource> Contains all the params for building the video request
 *  @return NSURLRequest video request
 */
+ (NSURLRequest *)videoRequest:(id<KPViewControllerDatasource>)params;
@end
