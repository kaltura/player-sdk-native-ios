//
//  KPFairPlayAssetResourceLoaderHandler.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 09/08/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPFairPlayAssetResourceLoaderHandler.h"
#import "KPLog.h"

NSString* const TAG = @"com.kaltura.playersdk.drm.fps";
NSString* const SKD_URL_SCHEME_NAME = @"skd";

@implementation KPFairPlayAssetResourceLoaderHandler
- (NSData *)getContentKeyAndLeaseExpiryfromKeyServerModuleWithRequest:(NSData *)requestBytes contentIdentifierHost:(NSString *)assetStr leaseExpiryDuration:(NSTimeInterval *)expiryDuration error:(NSError **)errorOut {
    
    NSString* licenseUri = _licenseUri;
    
    NSURL* reqUrl = [NSURL URLWithString:licenseUri];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:reqUrl];
    request.HTTPMethod=@"POST";
    request.HTTPBody=[requestBytes base64EncodedDataWithOptions:0];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    
    NSHTTPURLResponse* response = nil;
    
    KPLogDebug(@"Sending license request");
    NSTimeInterval licenseResponseTime = [NSDate timeIntervalSinceReferenceDate];
    
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:errorOut];
    
    licenseResponseTime = [NSDate timeIntervalSinceReferenceDate] - licenseResponseTime;
    KPLogDebug(@"Received license response (%.3f)", licenseResponseTime);
    
    if (!responseData) {
        KPLogError(@"No license response, error=%@", *errorOut);
        return nil;
    }
    
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:errorOut];
    if (!dict) {
        KPLogError(@"Invalid license response, error=%@", *errorOut);
        return nil;
    }
    
    NSString* errMessage = dict[@"message"];
    if (errMessage) {
        *errorOut = [NSError errorWithDomain:TAG code:'CKCE' userInfo:@{@"ServerMessage": errMessage}];
        KPLogError(@"Error message from license server: %@", errMessage);
        return nil;
    }
    NSString* ckc = dict[@"ckc"];
    NSString* expiry = dict[@"expiry"];
    
    if (!ckc) {
        *errorOut = [NSError errorWithDomain:TAG code:'NCKC' userInfo:nil];
        KPLogError(@"No CKC in license response");
        return nil;
    }
    
    NSData* ckcData = [[NSData alloc] initWithBase64EncodedString:ckc options:0];
    
    if (![ckcData length]) {
        *errorOut = [NSError errorWithDomain:TAG code:'ICKC' userInfo:nil];
        KPLogError(@"Invalid CKC in license response");
        return nil;
    }
    
    *expiryDuration = [expiry floatValue];
    
    return ckcData;
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
    
    // Use the SKD URL as assetId.
    NSString *assetId = url.host;
    
    // Wait for licenseUri and certificate, up to 5 seconds. In particular, the certificate might not be ready yet.
    // TODO: a better way of doing it is semaphores of some kind. 
    for (int i=0; i < 5*1000/50 && !(_certificate && _licenseUri); i++) {
        struct timespec delay;
        delay.tv_nsec = 50*1000*1000; // 50 millisec
        delay.tv_sec = 0;
        nanosleep(&delay, &delay);
    }
    
    if (!self.certificate) {
        KPLogError(@"Certificate is invalid or not set, can't continue");
        return NO;
    }
    
    // Get SPC
    NSData *requestBytes = [loadingRequest streamingContentKeyRequestDataForApp:self.certificate
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
