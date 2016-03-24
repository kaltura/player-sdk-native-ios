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
    if ([request.URL.absoluteString containsString:LocalContentIDKey]) {
        NSString *newContentID = request.URL.absoluteString.extractLocalContentId;
        if (![localContentID isEqualToString:newContentID]) {
            self.localContentID = newContentID;
        }
    }
    
    if ([NSURLProtocol propertyForKey:KPURLProtocolHandledKey inRequest:request]) {
        return NO;
    }
    
    if ([request.URL.absoluteString containsString:CacheManager.baseURL]) {
        for (NSString *key in CacheManager.withDomain.allKeys) {
            if ([request.URL.absoluteString containsString:key]) {
                return YES;
            }
        }
    } else {
        for (NSString *key in CacheManager.subStrings.allKeys) {
            if ([request.URL.absoluteString containsString:key]) {
                return YES;
            }
        }
    }
    return NO;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void) startLoading {
    NSString *requestStr = self.request.URL.absoluteString;
    
    // TODO:: optimize 
    if (self.class.localContentID && [requestStr containsString:@"mwEmbedFrame.php"] && ![requestStr containsString:LocalContentIDKey]) {
        requestStr = [NSString stringWithFormat:@"%@#localContentId=%@",self.request.URL.absoluteString, self.class.localContentID];
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
        
    } else {
        _cacheParams = [CachedURLParams new];
        _cacheParams.url = self.request.URL;
        NSMutableURLRequest *newRequest = [self.request mutableCopy];
        [NSURLProtocol setProperty:@YES forKey:KPURLProtocolHandledKey inRequest:newRequest];
    
        self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
        
    }
}

- (void) stopLoading {
    
    [self.connection cancel];
    _cacheParams.data = nil;
    
}

#pragma mark - NSURLConnectionDelegate

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    
    _cacheParams.response = (NSHTTPURLResponse *)response;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    if (response) {
        NSHTTPURLResponse *_response = (NSHTTPURLResponse *)response;
        _cacheParams.response = _response;
        NSString *location = _response.allHeaderFields[@"Location"];
        NSURL *url = [NSURL URLWithString:location];
        return [NSURLRequest requestWithURL:url];
    }
    return request;
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    
    [_cacheParams.data appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
    [_cacheParams storeCacheResponse];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}


@end
