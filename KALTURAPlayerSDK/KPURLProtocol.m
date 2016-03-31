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
    KPLogDebug(@"Enter::request:%@", request.URL.absoluteString);
    
    if ([request.URL.absoluteString containsString:LocalContentIDKey]) {
        NSString *newContentID = request.URL.absoluteString.extractLocalContentId;
        if (![localContentID isEqualToString:newContentID]) {
            self.localContentID = newContentID;
        }
    }
    
    if ([NSURLProtocol propertyForKey:KPURLProtocolHandledKey inRequest:request]) {
        KPLogDebug(@"Exit::NO (KPURLProtocolHandledKey)");
        return NO;
    }
    
    if ([request.URL.absoluteString containsString:CacheManager.baseURL]) {
        for (NSString *key in CacheManager.withDomain.allKeys) {
            if ([request.URL.absoluteString containsString:key]) {
                KPLogDebug(@"Exit::YES, key(baseURL):%@",key);
                return YES;
            }
        }
    } else {
        for (NSString *key in CacheManager.subStrings.allKeys) {
            if ([request.URL.absoluteString containsString:key]) {
                KPLogDebug(@"Exit::YES, key(subStrings):%@",key);
                return YES;
            }
        }
    }
    
    KPLogDebug(@"Exit::NO");
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    KPLogDebug(@"Enter");
    KPLogDebug(@"Exit::request:%@", request.URL.absoluteString);
    return request;
}

- (void)startLoading {
    KPLogDebug(@"Enter");
    NSString *requestStr = self.request.URL.absoluteString;
    
    // TODO:: optimize 
    if (self.class.localContentID && [requestStr containsString:@"mwEmbedFrame.php"] && ![requestStr containsString:LocalContentIDKey]) {
        requestStr = [NSString stringWithFormat:@"%@#localContentId=%@",self.request.URL.absoluteString, self.class.localContentID];
    }
    
    if ([requestStr containsString:@"playManifest"] && ![Utilities hasConnectivity]) {
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:200
                                                                 HTTPVersion:nil
                                                                headerFields:nil];
        [self.client URLProtocol:self
              didReceiveResponse:response
              cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:[NSData new]];
        [self.client URLProtocolDidFinishLoading:self];
        KPLogDebug(@"Exit::playManifest");
        
        return;
    }
    
    NSDictionary *cachedHeaders = requestStr.cachedResponseHeaders;
    NSData *cachedPage = requestStr.cachedPage;
    
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
        KPLogDebug(@"Exit::request:%@", self.request.URL.absoluteString);
        
    } else {
        _cacheParams = [CachedURLParams new];
        _cacheParams.url = self.request.URL;
        NSMutableURLRequest *newRequest = [self.request mutableCopy];
        [NSURLProtocol setProperty:@YES forKey:KPURLProtocolHandledKey inRequest:newRequest];
        self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
        KPLogDebug(@"Exit::newRequest:%@", newRequest);
    }
}

- (void) stopLoading {
    [self.connection cancel];
    _cacheParams.data = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    KPLogDebug(@"Enter");
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    _cacheParams.response = (NSHTTPURLResponse *)response;
    KPLogDebug(@"Exit::response:%@", response.URL.absoluteString);
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    KPLogDebug(@"Enter");
    
    if (response) {
        NSHTTPURLResponse *_response = (NSHTTPURLResponse *)response;
        _cacheParams.response = _response;
        NSString *location = _response.allHeaderFields[@"Location"];
        NSURL *url = [NSURL URLWithString:location];
        KPLogDebug(@"Exit::redirectResponse:%@", response.URL.absoluteString);
        
        return [NSURLRequest requestWithURL:url];
    }
    
    KPLogDebug(@"Exit::redirectResponse:%@", request.URL.absoluteString);
    
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    KPLogDebug(@"Enter");
    [self.client URLProtocol:self didLoadData:data];
    [_cacheParams.data appendData:data];
    KPLogDebug(@"Exit");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    KPLogDebug(@"Enter");
    [self.client URLProtocolDidFinishLoading:self];
    [_cacheParams storeCacheResponse];
    KPLogDebug(@"Exit");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    KPLogDebug(@"Enter");
    [self.client URLProtocol:self didFailWithError:error];
    KPLogDebug(@"Exit::error:%@", error.localizedDescription);
}


@end
