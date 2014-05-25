//
//  KPEventListener.h
//  PlayerSDK
//
//  Created by Eliza Sapir on 5/24/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^KPEventListenerBlock)();
@interface KPEventListener : NSObject

@property (nonatomic, readonly) KPEventListenerBlock eventListener;
@property (nonatomic, readonly) NSString *name;

-(id) initWithBlock:(KPEventListenerBlock)eventListener andName:(NSString *)name;
+(KPEventListener *) eventListener:(KPEventListenerBlock)block withName:(NSString *)name;

@end
