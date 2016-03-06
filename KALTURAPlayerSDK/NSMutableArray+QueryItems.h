//
//  NSMutableArray+QueryItems.h
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 14/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueryItems)
-(void)addQueryParam:(NSString*)key value:(NSString*)value;
@end
