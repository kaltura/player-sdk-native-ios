//
//  KPFlashvarObject.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 12/2/14.
//  Copyright (c) 2014 Kaltura. All rights reserved.
//

#import "KPPlayerConfig.h"
#import "DeviceParamsHandler.h"
#import "NSString+Utilities.h"

/// Key names of the video request
static NSString *EntryIdKey = @"entry_id";


@interface KPPlayerConfig()

@property (nonatomic, copy) NSMutableDictionary *paramsDict;
@property (nonatomic, copy) NSURL *url;

@end

@implementation KPPlayerConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        _supportedInterfaceOrientations = UIInterfaceOrientationMaskAll;
        return self;
    }
    return nil;
}

- (instancetype)initWithDomain:(NSString *)domain
                      uiConfID:(NSString *)uiConfId
                      partnerId:(NSString *)partnerId {
    self = [self init];
    if (self && domain && uiConfId && partnerId) {
        _domain = domain;
        _uiConfId = uiConfId;
        _partnerId = partnerId;
        return self;
    }
    return nil;
}

- (NSMutableDictionary *)paramsDict {
    if (!_paramsDict) {
        _paramsDict = [NSMutableDictionary new];
    }
    return _paramsDict;
}

- (void)addConfigKey:(NSString *)key withValue:(NSString *)value; {
    if (key && key.length && value && value.length) {
        NSString *configKey = [NSString stringWithFormat:@"flashvars[%@]", key];
        self.paramsDict[configKey] = value;
    }
}

- (NSDictionary *)flashvarsDict {
    return self.paramsDict.copy;
}


- (void)setEntryId:(NSString *)entryId {
    if (entryId) {
        _entryId = entryId;
        self.paramsDict[EntryIdKey] = entryId;
    }
}

- (NSURL *)videoURL {
    if (!_url) {
        NSString *link = [_domain stringByAppendingFormat:@"/p/%@/sp/%@00/embedIframeJs/uiconf_id/%@/partner_id/%@?", _partnerId, _partnerId, _uiConfId, _partnerId];
        for (NSString *key in self.paramsDict.allKeys) {
            link = [link stringByAppendingFormat:@"%@=%@&", key, self.paramsDict[key]];
        }
        link = [[link substringToIndex:link.length - 1] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        _url = [NSURL URLWithString:link];
    }
    return _url;
}

- (NSURL *)appendConfiguration:(NSURL *)videoURL {
    NSString *url = videoURL.absoluteString;
    if (_advertiserID) {
        url = [url appendIDFA:_advertiserID];
    }
    if (_enableHover) {
        url = url.appendHover;
    }
    url = url.appendIFrameEmbed;
    return [NSURL URLWithString:url];
}
@end
