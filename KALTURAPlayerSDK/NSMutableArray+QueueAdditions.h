//
//  NSMutableArray+QueueAdditions.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 9/21/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (QueueAdditions)
- (void)enqueue:(id)obj;
- (id)dequeue;
- (id)peek:(int)index;
- (id)peekHead;
- (id)peekTail;
- (BOOL)empty;
@end
