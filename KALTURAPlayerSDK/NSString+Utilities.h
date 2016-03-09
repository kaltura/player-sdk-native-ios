//
//  NSString+Utilities.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPViewControllerProtocols.h"

extern NSString *const LocalContentId;

typedef struct FunctionComponents {
    __unsafe_unretained NSString *name;
    __unsafe_unretained NSArray *args;
    __unsafe_unretained NSError *error;
    int callBackID;
}FunctionComponents;



@interface NSString (Utilities)
- (NSString *)appendParam:(NSDictionary *)param;

@property (nonatomic, copy, readonly) NSString *appendVersion;
@property (nonatomic, copy, readonly) NSString *appendHover;
@property (nonatomic, copy, readonly) NSString *appendIFrameEmbed;
@property (nonatomic, copy, readonly) NSString *sqlite;

@property (nonatomic, copy, readonly) NSString *extractLocalContentId;

- (NSString *)appendIDFA:(NSString *)IDFA;

@property (nonatomic, readonly) Attribute attributeEnumFromString;
@property (nonatomic, readonly) BOOL isJSFrame;
@property (nonatomic, readonly) BOOL isFrameURL;
@property (nonatomic, readonly) FunctionComponents extractFunction;

@property (nonatomic, readonly) BOOL isPlay;
@property (nonatomic, readonly) BOOL isPause;
@property (nonatomic, readonly) BOOL isStop;
@property (nonatomic, readonly) BOOL isTimeUpdate;
@property (nonatomic, readonly) BOOL isToggleFullScreen;
@property (nonatomic, readonly) BOOL isSeeked;
@property (nonatomic, readonly) BOOL canPlay;
@property (nonatomic, readonly) BOOL isDurationChanged;
@property (nonatomic, readonly) BOOL isMetadata;
@property (nonatomic, readonly) BOOL isFrameKeypath;

@property (nonatomic, copy, readonly) NSString *md5;
@property (nonatomic, copy, readonly) NSString *documentPath;
@property (nonatomic, copy, readonly) NSURL *sorted;

@property (nonatomic, readonly) BOOL isWV;
#pragma mark
#pragma mark JavaScriptEvents Double Click helpers
@property (nonatomic, copy, readonly) NSDictionary *nullVal;
@property (nonatomic, copy, readonly) NSDictionary *adLoaded;
@property (nonatomic, copy, readonly) NSDictionary *adStart;
@property (nonatomic, copy, readonly) NSDictionary *adCompleted;
@property (nonatomic, copy, readonly) NSDictionary *adRemainingTimeChange;
@property (nonatomic, copy, readonly) NSDictionary *adClicked;
@property (nonatomic, copy, readonly) NSDictionary *adSkipped;

#pragma mark
#pragma mark JavaScriptEvents
@property (nonatomic, copy, readonly) NSString *addJSListener;
@property (nonatomic, copy, readonly) NSString *removeJSListener;

@end
