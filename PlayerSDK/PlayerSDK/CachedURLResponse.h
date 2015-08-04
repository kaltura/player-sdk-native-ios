//
//  CachedURLResponse.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/3/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CachedURLResponse : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * encoding;
@property (nonatomic, retain) NSString * mimeType;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * url;

@end
