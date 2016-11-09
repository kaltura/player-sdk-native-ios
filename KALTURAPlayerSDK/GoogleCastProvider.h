//
//  GoogleCastProvider.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 18/09/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPCastProvider.h"
#if GOOGLE_CAST_ENABLED
#import <GoogleCast/GoogleCast.h>
#endif

@interface GoogleCastProvider : NSObject <KPCastProvider>
+ (GoogleCastProvider *)sharedInstance;
@end
