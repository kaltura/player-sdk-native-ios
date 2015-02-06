//
//  KCachedPages.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 2/6/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface KCachedPages : NSManagedObject

@property (nonatomic, retain) NSString * hasedLink;
@property (nonatomic, retain) NSDate * storeTimeStamp;
@property (nonatomic, retain) NSData * content;
@property (nonatomic, retain) NSString * baseURL;

@end
