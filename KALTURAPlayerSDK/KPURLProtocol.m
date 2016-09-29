//
//  KPURLProtocol.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/2/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPURLProtocol.h"
#import "KCacheManager.h"
#import "NSDictionary+Cache.h"
#import "NSString+Utilities.h"
#import <libkern/OSAtomic.h>
#import "Utilities.h"
#import "KPLog.h"


static NSString * const KPURLProtocolHandledKey = @"KPURLProtocolHandledKey";
static NSString * const LocalContentIDKey = @"localContentId";

static int32_t enableCount;

@interface KPURLProtocol()<NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
//@property (nonatomic, strong) NSMutableData *mutableData;
//@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) CachedURLParams *cacheParams;

@end

@implementation KPURLProtocol

+(void)enable {
    if (OSAtomicIncrement32(&enableCount) == 1) {
        [NSURLProtocol registerClass:self];
    }
}

+(void)disable {
    if (OSAtomicDecrement32(&enableCount) == 0) {
        [NSURLProtocol unregisterClass:self];
    }
}

static NSString *localContentID = nil;

+ (NSString *)localContentID {
    @synchronized(self) {
        return localContentID;
    }
}

+ (void)setLocalContentID:(NSString *)contentId {
    @synchronized(self) {
        localContentID = contentId;
    }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    // To prevent duplicates, make this condition first and don't log anything.
    if ([NSURLProtocol propertyForKey:KPURLProtocolHandledKey inRequest:request]) {
        return NO;
    }
    
    KPLogTrace(@"Enter::request:%@", request.URL.absoluteString);
    
    KCacheManager* cacheManager = [KCacheManager shared];
    NSString* requestString = request.URL.absoluteString;
    
    BOOL shouldCacheRequest = NO;
    
    // Special case mwEmbedFrame.php with localContentId.
    NSString *newContentID = requestString.extractLocalContentId;
    
    if (newContentID) {
        shouldCacheRequest = YES;
        if (![localContentID isEqualToString:newContentID]) {
            self.localContentID = newContentID;
        }
    }
    
    if (!shouldCacheRequest) {
        shouldCacheRequest = [cacheManager shouldCacheRequest:request];
    }
    
#ifdef LOG_CACHE_EVENTS
    if (!shouldCacheRequest) {
        NSLog(@"CACHE IGNORE: %@", requestString);
    }
#endif

    KPLogTrace(@"Exit::%d", shouldCacheRequest);
    return shouldCacheRequest;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    KPLogTrace(@"Enter");
    KPLogTrace(@"Exit::request:%@", request.URL.absoluteString);
    return request;
}

// This is hackish, so it needs explanation.
// Setting the request's timeout to a nonstandard number is the most reliable way I found for marking 
// it for ignoring local cache. The system's way of doing it (NSURLRequestReloadIgnoringLocalCacheData)
// is not good enough for our purposes, because it may set it on regular requests. Sometimes.
// The number: 60 (seconds) is the default timeout. So 61.0002 is almost the same, but different.

static NSTimeInterval const MagicTimeoutForIgnoringLocalCache = 61.0002;

// The caller has to call the next method on a request.
+(void)ignoreLocalCacheForRequest:(NSMutableURLRequest*)request {
    request.timeoutInterval = MagicTimeoutForIgnoringLocalCache;
}

+(BOOL)localCacheIgnoredForRequest:(NSURLRequest*)request {
    return request.timeoutInterval == MagicTimeoutForIgnoringLocalCache;
}

- (void)startLoading {
    KPLogTrace(@"Enter");
    NSString *requestStr = self.request.URL.absoluteString;
    KPLogTrace(@"requestStr: %@", requestStr);
    
    // TODO:: optimize 
    if (self.class.localContentID && [requestStr containsString:@"/mwEmbedFrame.php"] && ![requestStr containsString:LocalContentIDKey]) {
        requestStr = [NSString stringWithFormat:@"%@#localContentId=%@",self.request.URL.absoluteString, self.class.localContentID];
    }
    
    KCacheManager* cacheManager = [KCacheManager shared];
    
    BOOL online = [Utilities hasConnectivity];
    
    if (!online) {
        for (NSString *key in cacheManager.offlineSubStr.allKeys) {
            if ([requestStr containsString:key]) {
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                          statusCode:200
                                                                         HTTPVersion:nil
                                                                        headerFields:nil];
                [self.client URLProtocol:self
                      didReceiveResponse:response
                      cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                [self.client URLProtocol:self didLoadData:[NSData new]];
                [self.client URLProtocolDidFinishLoading:self];
                KPLogTrace(@"offline mode - return status 200 & empty for key:%@", key);
                
                return;
            }
        }
    }

    NSDictionary *cachedHeaders;
    NSData *cachedPage;
    
    NSLog(@"timeout: %f", self.request.timeoutInterval);
    if ([self.class localCacheIgnoredForRequest:self.request]) {
        KPLogDebug(@"NOTE: local cache data explicitly ignored for request: %@", self.request);
    } else {
        cachedHeaders = requestStr.cachedResponseHeaders;
        cachedPage = requestStr.cachedPage;
    }
    
    if (cachedHeaders && cachedPage && cachedPage.length) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:[cachedHeaders[@"statusCode"] integerValue]
                                                                 HTTPVersion:nil
                                                                headerFields:cachedHeaders[@"allHeaderFields"]];
        [self.client URLProtocol:self
              didReceiveResponse:response
              cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:cachedPage];
        [self.client URLProtocolDidFinishLoading:self];
        KPLogTrace(@"Exit::finishedLoadingFromCache:%@", self.request.URL);
        
    } else {
        
        if (!online) {
            KPLogWarn(@"NOTE: device is offline and a whitelisted resource is missing (%@). Player may not function correctly.", requestStr);
        }
        
        _cacheParams = [CachedURLParams new];
        _cacheParams.url = self.request.URL;
        
        NSMutableURLRequest *newRequest = [self.request mutableCopy];
        [NSURLProtocol setProperty:@YES forKey:KPURLProtocolHandledKey inRequest:newRequest];
        self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
        KPLogTrace(@"Exit::newRequest:%@", newRequest);
    }
}

- (void) stopLoading {
    [self.connection cancel];
    _cacheParams.data = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    KPLogTrace(@"Enter");
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    _cacheParams.response = (NSHTTPURLResponse *)response;
    KPLogTrace(@"Exit::response:%@", response.URL.absoluteString);
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    KPLogTrace(@"Enter");
    
    if (response) {
        NSHTTPURLResponse *_response = (NSHTTPURLResponse *)response;
        _cacheParams.response = _response;
        NSString *location = _response.allHeaderFields[@"Location"];
        NSURL *url = [NSURL URLWithString:location];
        KPLogTrace(@"Exit::redirectResponse:%@", response.URL.absoluteString);
        
        return [NSURLRequest requestWithURL:url];
    }
    
    KPLogTrace(@"Exit::redirectResponse:%@", request.URL.absoluteString);
    
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    KPLogTrace(@"Enter");
    [self.client URLProtocol:self didLoadData:data];
    [_cacheParams.data appendData:data];
    KPLogTrace(@"Exit");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    KPLogTrace(@"Enter");
    [self.client URLProtocolDidFinishLoading:self];
    [_cacheParams storeCacheResponse];
    KPLogTrace(@"Exit");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    KPLogTrace(@"Enter");
    [self.client URLProtocol:self didFailWithError:error];
    KPLogTrace(@"Exit::error:%@", error.localizedDescription);
}


@end
