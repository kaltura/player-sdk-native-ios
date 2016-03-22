//
//  FairPlayHandler.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 22/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPFairPlayHandler.h"
#import "KPAssetBuilder.h"
#import "KPLog.h"

NSString* const SKD_URL_SCHEME_NAME = @"skd";

@interface KPFairPlayHandler () {
    NSString* _licenseUri;
    KPAssetReadyCallback _assetReadyCallback;
}
@end

static dispatch_queue_t	globalNotificationQueue( void )
{
    static dispatch_queue_t globalQueue = 0;
    static dispatch_once_t getQueueOnce = 0;
    dispatch_once(&getQueueOnce, ^{
        globalQueue = dispatch_queue_create("fairplay notify queue", NULL);
    });
    return globalQueue;
}



@implementation KPFairPlayHandler

-(instancetype)initWithAssetReadyCallback:(KPAssetReadyCallback)callback {
    self = [super init];
    if (self) {
        _assetReadyCallback = [callback copy];
    }
    return self;
}

-(void)setContentUrl:(NSString*)url {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:url] options:nil];
    
    [asset.resourceLoader setDelegate:self queue:globalNotificationQueue()];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _assetReadyCallback(asset);
    });
}

-(void)setLicenseUri:(NSString*)licenseUri {
    _licenseUri = licenseUri;
}

- (NSData *)getContentKeyAndLeaseExpiryfromKeyServerModuleWithRequest:(NSData *)requestBytes contentIdentifierHost:(NSString *)assetStr leaseExpiryDuration:(NSTimeInterval *)expiryDuration error:(NSError **)errorOut {
    NSData *decodedData = nil;
    
    NSString* licenseUri = _licenseUri;
    
    NSURL* reqUrl = [NSURL URLWithString:licenseUri];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:reqUrl];
    request.HTTPMethod=@"POST";
    //    request.HTTPBody=[requestBytes base64EncodedDataWithOptions:0];
    request.HTTPBody=[requestBytes base64EncodedDataWithOptions:0];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    NSHTTPURLResponse* response = nil;
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:errorOut];
    if (!responseData) {
        KPLogError(@"No license response, error=%@", *errorOut);
        return nil;
    }
    
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:errorOut];
    if (!dict) {
        KPLogError(@"Invalid license response, error=%@", *errorOut);
        return nil;
    }

    decodedData = [[NSData alloc] initWithBase64EncodedString:dict[@"ckc"] options:0];
    *expiryDuration = [dict[@"expiry"] floatValue];
    
    //	*errorOut = [NSError errorWithDomain:NSPOSIXErrorDomain code:1 userInfo:nil];
    return decodedData;
}



- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    AVAssetResourceLoadingDataRequest *dataRequest = loadingRequest.dataRequest;
    NSURL *url = loadingRequest.request.URL;
    NSError *error = nil;
    BOOL handled = NO;
    
    // Must be a non-standard URI scheme for AVFoundation to invoke your AVAssetResourceLoader delegate
    // for help in loading it.
    if (![[url scheme] isEqual:SKD_URL_SCHEME_NAME]) {
        return NO;
    }
    
    NSLog( @"shouldWaitForLoadingOfURLRequest got %@", loadingRequest);
    
    // TODO: assetid?
    NSString *assetId = @"123";
    
    NSData *certificate = [KPAssetBuilder getCertificate];
    
    if (!certificate) {
        return NO;
    }
    
    // Get SPC
    NSData *requestBytes = [loadingRequest streamingContentKeyRequestDataForApp:certificate
                                                      contentIdentifier:[assetId dataUsingEncoding:NSUTF8StringEncoding]
                                                                options:nil
                                                                  error:&error];
    
    NSTimeInterval expiryDuration = 0.0;
    
    // Send the SPC message to the Key Server.
    NSData *responseData = [self getContentKeyAndLeaseExpiryfromKeyServerModuleWithRequest:requestBytes
                                                             contentIdentifierHost:assetId
                                                               leaseExpiryDuration:&expiryDuration
                                                                             error:&error];
    
    // The Key Server returns the CK inside an encrypted Content Key Context (CKC) message in response to
    // the app’s SPC message.  This CKC message, containing the CK, was constructed from the SPC by a
    // Key Security Module in the Key Server’s software.
    if (responseData != nil) {
        
        // Provide the CKC message (containing the CK) to the loading request.
        [dataRequest respondWithData:responseData];
        
        // Get the CK expiration time from the CKC. This is used to enforce the expiration of the CK.
        if (expiryDuration != 0.0) {
            
            AVAssetResourceLoadingContentInformationRequest *infoRequest = loadingRequest.contentInformationRequest;
            if (infoRequest) {
                
                // Set the date at which a renewal should be triggered.
                // Before you finish loading an AVAssetResourceLoadingRequest, if the resource
                // is prone to expiry you should set the value of this property to the date at
                // which a renewal should be triggered. This value should be set sufficiently
                // early enough to allow an AVAssetResourceRenewalRequest, delivered to your
                // delegate via -resourceLoader:shouldWaitForRenewalOfRequestedResource:, to
                // finish before the actual expiry time. Otherwise media playback may fail.
                infoRequest.renewalDate = [NSDate dateWithTimeIntervalSinceNow:expiryDuration];
                
                infoRequest.contentType = @"application/octet-stream";
                infoRequest.contentLength = responseData.length;
                infoRequest.byteRangeAccessSupported = NO;
            }
        }
        [loadingRequest finishLoading]; // Treat the processing of the request as complete.
    }
    else {
        [loadingRequest finishLoadingWithError:error];
    }
    
    handled = YES;	// Request has been handled regardless of whether server returned an error.
    
    return handled;
}


/* -----------------------------------------------------------------------------
 **
 ** resourceLoader: shouldWaitForRenewalOfRequestedResource:
 **
 ** Delegates receive this message when assistance is required of the application
 ** to renew a resource previously loaded by
 ** resourceLoader:shouldWaitForLoadingOfRequestedResource:. For example, this
 ** method is invoked to renew decryption keys that require renewal, as indicated
 ** in a response to a prior invocation of
 ** resourceLoader:shouldWaitForLoadingOfRequestedResource:. If the result is
 ** YES, the resource loader expects invocation, either subsequently or
 ** immediately, of either -[AVAssetResourceRenewalRequest finishLoading] or
 ** -[AVAssetResourceRenewalRequest finishLoadingWithError:]. If you intend to
 ** finish loading the resource after your handling of this message returns, you
 ** must retain the instance of AVAssetResourceRenewalRequest until after loading
 ** is finished. If the result is NO, the resource loader treats the loading of
 ** the resource as having failed. Note that if the delegate's implementation of
 ** -resourceLoader:shouldWaitForRenewalOfRequestedResource: returns YES without
 ** finishing the loading request immediately, it may be invoked again with
 ** another loading request before the prior request is finished; therefore in
 ** such cases the delegate should be prepared to manage multiple loading
 ** requests.
 **
 ** -------------------------------------------------------------------------- */

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest {
    return [self resourceLoader:resourceLoader shouldWaitForLoadingOfRequestedResource:renewalRequest];
}

@end
