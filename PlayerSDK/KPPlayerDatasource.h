//
//  KPPlayerDatasource.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPViewControllerProtocols.h"


@interface KPPlayerDatasource : NSObject

@property (nonatomic, weak) id<KPViewControllerDatasource> params;
@property (nonatomic, copy, readonly) NSURLRequest *videoRequest;
@end
