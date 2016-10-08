//
//  KPControlsView.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 4/12/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPControlsView.h"
#import "DeviceParamsHandler.h"

#define KP_CONTROLS_WEBVIEW  SYSTEM_VERSION_GREATER_THAN(@"10") ? @"KPControlsUIWebview" : @"KPControlsWKWebview"

NSString *sendNotification(NSString *notification, NSString *params) {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.sendNotification(\"%@\" ,%@);", notification, params];
}

NSString *setKDPAttribute(NSString *pluginName, NSString *propertyName, NSString *value) {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.setKDPAttribute('%@','%@', %@);", pluginName, propertyName, value];
}

NSString *triggerEvent(NSString *event, NSString *value) {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.trigger('%@', '%@')", event, value];
}

NSString *triggerEventWithJSON(NSString *event, NSString *jsonString) {
    return [NSString stringWithFormat:@"NativeBridge.videoPlayer.trigger('%@', %@)", event, jsonString];
}

NSString *asyncEvaluate(NSString *expression, NSString *evaluateID) {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.asyncEvaluate(\"%@\", \"%@\");", expression, evaluateID];
}

NSString *showChromecastComponent(BOOL show) {
    return [NSString stringWithFormat: @"NativeBridge.videoPlayer.showChromecastComponent(\"%@\");", @(show).stringValue];
}

@implementation KPControlsView
+ (id<KPControlsView>)defaultControlsViewWithFrame:(CGRect)frame {
    NSString *webViewType = ([[NSProcessInfo processInfo] operatingSystemVersion].majorVersion > 9) ?  @"KPControlsWKWebview" : @"KPControlsUIWebview";
    return (id<KPControlsView>)[[NSClassFromString(webViewType) alloc] initWithFrame:frame];
}
@end
