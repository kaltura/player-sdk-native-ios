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
    
    if ([requestString containsString:LocalContentIDKey]) {
        NSString *newContentID = request.URL.absoluteString.extractLocalContentId;
        if (![localContentID isEqualToString:newContentID]) {
            self.localContentID = newContentID;
        }
    }

    BOOL result = [cacheManager shouldCacheRequest:request];

    
    KPLogTrace(@"Exit::%d", result);
    return result;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    KPLogTrace(@"Enter");
    KPLogTrace(@"Exit::request:%@", request.URL.absoluteString);
    return request;
}

- (void)startLoading {
    KPLogTrace(@"Enter");
    NSString *requestStr = self.request.URL.absoluteString;
    KPLogTrace(@"requestStr: %@", requestStr);
    
    // TODO:: optimize 
    if (self.class.localContentID && [requestStr containsString:@"mwEmbedFrame.php"] && ![requestStr containsString:LocalContentIDKey]) {
        requestStr = [NSString stringWithFormat:@"%@#localContentId=%@",self.request.URL.absoluteString, self.class.localContentID];
    }
    
    KCacheManager* cacheManager = [KCacheManager shared];
    
    if (![Utilities hasConnectivity]) {
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
                KPLogTrace(@"oflline mode - return status 200 & empty for key:%@", key);
                
                return;
            }
        }
    }
    
    NSDictionary *cachedHeaders = requestStr.cachedResponseHeaders;
    NSData *cachedPage = requestStr.cachedPage;
    
    if (self.request.cachePolicy!=NSURLRequestReloadIgnoringLocalCacheData && cachedHeaders && cachedPage && cachedPage.length) {
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
