//
//  KPLog.m
//  Created by Nissim Pardo on 3/25/14.
//

#import "KPLog.h"

NSString *const KPLoggingNotification = @"KPLoggingNotification";
NSString *const KPLogMessageKey = @"KPLogMessageKey";
NSString *const KPLogMessageLevelKey = @"KPLogMessageLevelKey";


void _KPLog(KPLogLevel logLevel,  NSString *methodName, int lineNumber,NSString *format, ...) {
    format = [NSString stringWithFormat:@"\n::%@:: %@ (line:%d)\n%@\n",KPLogManager.levelNames[logLevel / 10], methodName, lineNumber,format];
    va_list args;
    va_start(args, format);
    notifyListener([[[NSString alloc] initWithFormat:format arguments:args] init], logLevel);
    va_end(args);
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}

void notifyListener(NSString *message, NSInteger messageLevel) {
    [[NSNotificationCenter defaultCenter] postNotificationName:KPLoggingNotification
                                                        object:nil
                                                      userInfo:@{KPLogMessageKey: message,
                                                                 KPLogMessageLevelKey: @(messageLevel)}];
}

