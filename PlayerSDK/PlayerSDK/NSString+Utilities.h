//
//  NSString+Utilities.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPViewControllerProtocols.h"

typedef struct FunctionComponents {
    __unsafe_unretained NSString *name;
    __unsafe_unretained NSArray *args;
    __unsafe_unretained NSError *error;
    int callBackID;
}FunctionComponents;

@interface NSString (Utilities)
- (NSString *)appendParam:(NSDictionary *)param;

@property (nonatomic, assign, readonly) Attribute attributeEnumFromString;
@property (nonatomic, assign, readonly) BOOL isJSFrame;
@property (nonatomic, assign, readonly) FunctionComponents extractFunction;

@property (nonatomic, assign, readonly) BOOL isPlay;
@property (nonatomic, assign, readonly) BOOL isPause;
@property (nonatomic, assign, readonly) BOOL isStop;

#pragma mark
#pragma mark JavaScriptEvents
- (NSString *)asyncEvaluateWithListenerName:(NSString *)name;
- (NSString *)sendNotificationWithBody:(NSString *)body;
- (NSString *)setKDPAttribute:(NSString *)attribute value:(NSString *)value;
- (NSString *)triggerEvent:(NSString *)event;
@property (nonatomic, copy, readonly) NSString *addJSListener;
@property (nonatomic, copy, readonly) NSString *removeJSListener;
@end
