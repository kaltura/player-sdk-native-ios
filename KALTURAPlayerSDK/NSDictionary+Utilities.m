//
//  NSDictionary+Utilities.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/12/2015.
//  Copyright © 2015 Kaltura. All rights reserved.
//

#import "NSDictionary+Utilities.h"
#import "KPLog.h"

@implementation NSDictionary (Utilities)
- (NSString *)toJson {
    NSError *error = nil;
    NSData *toJson = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
    if (error) {
        KPLogError(@"%@", error);
        return nil;
    }
    NSString *jsonStr = [[NSString alloc] initWithData:toJson encoding:NSUTF8StringEncoding];
    return [jsonStr stringByReplacingOccurrencesOfString:@"\"null\"" withString:@"null"];
}
@end
