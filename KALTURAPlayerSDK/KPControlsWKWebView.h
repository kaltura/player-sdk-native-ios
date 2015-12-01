//
//  KPControlsWKWebview.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 4/12/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "KPControlsView.h"

@interface KPControlsWKWebview : WKWebView <KPControlsView, WKUIDelegate>

@end
