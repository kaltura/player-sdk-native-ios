//
//  KPEventListener.m
//  PlayerSDK
//
//  Created by Eliza Sapir on 5/24/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPEventListener.h"

@implementation KPEventListener
@synthesize eventListener = _eventListener;
@synthesize name = _name;

- (id)initWithBlock: (KPEventListenerBlock)eventListener andName: (NSString *)name {
    self = [super init];
    _eventListener = eventListener;
    _name = name;
    return self;
}

+ (KPEventListener *)eventListener: (KPEventListenerBlock)block withName: (NSString *)name {
    return [ [KPEventListener alloc] initWithBlock: block andName: name ];
}

@end
