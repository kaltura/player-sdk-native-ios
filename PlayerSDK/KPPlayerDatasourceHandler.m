//
//  KPPlayerDatasource.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//



#import "KPPlayerDatasourceHandler.h"
#import "NSString+Utilities.h"

@implementation KPPlayerDatasourceHandler

+ (NSURLRequest *)videoRequest:(id<KPViewControllerDatasource>)params {
    NSString *link = params.serverAddress;
    if (link && link.length) {
        link = [link stringByAppendingString:@"?"];
    } else {
        return nil;
    }
    if ([params respondsToSelector:@selector(wid)] && params.wid) {
        link = [link appendParam:@{KPPlayerDatasourceWidKey: params.wid}];
    }
    if ([params respondsToSelector:@selector(uiConfId)] && params.uiConfId) {
        link = [link appendParam:@{KPPlayerDatasourceUiConfIdKey: params.uiConfId}];
    }
    if ([params respondsToSelector:@selector(cacheSt)] && params.cacheSt) {
        link = [link appendParam:@{KPPlayerDatasourceCacheStKey: params.cacheSt}];
    }
    if ([params respondsToSelector:@selector(entryId)] && params.entryId) {
        link = [link appendParam:@{KPPlayerDatasourceEntryId: params.entryId}];
    }
    if ([params respondsToSelector:@selector(playerId)] && params.playerId) {
        link = [link appendParam:@{KPPlayerDatasourcePlayerIdKey: params.playerId}];
    }
    if ([params respondsToSelector:@selector(urid)] && params.urid) {
        link = [link appendParam:@{KPPlayerDatasourceUridKey: params.urid}];
    }
    if ([params respondsToSelector:@selector(debug)] && params.debug) {
        link = [link appendParam:@{KPPlayerDatasourceDebugKey: params.debug}];
    }
    if ([params respondsToSelector:@selector(forceMobileHTML5)] && params.forceMobileHTML5) {
        link = [link appendParam:@{KPPlayerDatasourceForceHtml5Key: params.forceMobileHTML5}];
    }
    if ([params respondsToSelector:@selector(configFlags)] && params.configFlags) {
        for (NSString *key in params.configFlags.flashvarsDict.allKeys) {
            link = [link appendParam:@{key: params.configFlags.flashvarsDict[key]}];
        }
    }
    link = [link stringByReplacingOccurrencesOfString:@"?&" withString:@"?"];
    link = [link stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURLRequest requestWithURL:[NSURL URLWithString:link]];
}

@end
