//
//  Utilities.m
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 28/03/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Utilities.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "KPLog.h"

@implementation Utilities

+ (BOOL)hasConnectivity {
    KPLogDebug(@"Enter");
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if (reachability != NULL) {
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
                // If target host is not reachable
                KPLogDebug(@"Exit::NO");
                return NO;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
                // If target host is reachable and no connection is required
                //  then we'll assume (for now) that your on Wi-Fi
                KPLogDebug(@"Exit::YES");
                return YES;
            }
            
            
            if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
                 (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
                // The connection is on-demand (or on-traffic) if the
                // calling application is using the CFSocketStream or higher APIs.
                
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
                {
                    // no [user] intervention is needed
                    KPLogDebug(@"Exit::YES");
                    return YES;
                }
            }
            
            if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
            {
                // WWAN connections are OK if the calling application
                // is using the CFNetwork (CFSocketStream?) APIs.
                KPLogDebug(@"Exit::YES");
                return YES;
            }
        }
    }
    
    return NO;
}

@end
