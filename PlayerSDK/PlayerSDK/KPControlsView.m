//
//  KPControlsView.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 4/12/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPControlsView.h"
#import "DeviceParamsHandler.h"

@implementation KPControlsView
+ (id<KPControlsView>)defaultControlsViewWithFrame:(CGRect)frame {
    NSString *className = isIOS(8) ? @"KPControlsWKWebview" : @"KPControlsUIWebview";
    return (id<KPControlsView>)[[NSClassFromString(className) alloc] initWithFrame:frame];
}
@end
