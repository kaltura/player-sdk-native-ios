//
//  QLog.h
//  QadabraSDK
//
//  Created by Nissim Pardo on 3/25/14.
//  Copyright (c) 2014 Marimedia LTD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPLogManager.h"


extern NSString *const KPLoggingNotification;
extern NSString *const KPLogMessageKey;
extern NSString *const KPLogMessageLevelKey;


void _KPLog(KPLogLevel logLevel, NSString *methodName, int lineNumber, NSString *format, ...);
void notifyListener(NSString *message, NSInteger messageLevel);

#ifdef DEBUG
#define __FileName__ [[NSString stringWithUTF8String:__FILE__] lastPathComponent]
#define __LineNumber__ __LINE__
#define __MethodName__ [[NSString stringWithUTF8String:__func__] lastPathComponent]

#define KPLogTrace(...) KPLogManager.KPLogLevel <= KPLogLevelTrace ? _KPLog(KPLogLevelTrace,__MethodName__,__LineNumber__,__VA_ARGS__):nil
#define KPLogDebug(...) KPLogManager.KPLogLevel <= KPLogLevelDebug ? _KPLog(KPLogLevelDebug,__MethodName__,__LineNumber__,__VA_ARGS__):nil
#define KPLogInfo(...) KPLogManager.KPLogLevel <= KPLogLevelInfo ? _KPLog(KPLogLevelInfo,__MethodName__,__LineNumber__,__VA_ARGS__):nil
#define KPLogWarn(...) KPLogManager.KPLogLevel <= KPLogLevelWarn ? _KPLog(KPLogLevelWarn,__MethodName__,__LineNumber__,__VA_ARGS__):nil
#define KPLogError(...) KPLogManager.KPLogLevel <= KPLogLevelError ? _KPLog(KPLogLevelError,__MethodName__,__LineNumber__,__VA_ARGS__):nil
#else
#define KPLogTrace(...) /* */
#define KPLogDebug(...) /* */
#define KPLogInfo(...) /* */
#define KPLogWarn(...) /* */
#define KPLogError(...) /* */
#endif

#if !defined(DEBUGCC)
#define KPLogChromeCast(...)
#else
#define KPLogChromeCast(...) KPLogManager.KPLogLevel <= KPLogLevelChromeCast ? _KPLog(KPLogLevelChromeCast,__MethodName__,__LineNumber__,__VA_ARGS__):nil
#endif

#ifdef DEBUG
#    define DLog(...) NSLog(__VA_ARGS__)
#else
#    define DLog(...) /* */
#endif
#define ALog(...) NSLog(__VA_ARGS__)