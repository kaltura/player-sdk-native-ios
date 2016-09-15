//
//  KPFairPlayAssetResourceLoaderHandler.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 09/08/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPFairPlayAssetResourceLoaderHandler.h"
#import "KPLog.h"
#import "NSString+Utilities.h"

NSString* const TAG = @"com.kaltura.playersdk.drm.fps";
NSString* const SKD_URL_SCHEME_NAME = @"skd";

@implementation KPFairPlayAssetResourceLoaderHandler
- (NSData *)performLicenseRequest:(NSData *)requestBytes leaseExpiryDuration:(NSTimeInterval *)expiryDuration error:(NSError **)errorOut {
    
    NSString* licenseUri = _licenseUri;
    licenseUri = [licenseUri stringByReplacingOccurrencesOfString:@"udrm.kaltura.com" withString:@"udrm-stg.kaltura.com"];
    
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


-(NSURL*)contentKeyFileURLForAsset:(NSString*)assetId {
    NSError* error;
    NSURL* libraryDir = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:&error];
    // TODO: error
    
    
    
    NSURL* keyStoreDir = [libraryDir URLByAppendingPathComponent:@"KalturaKeyStore" isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:keyStoreDir withIntermediateDirectories:YES attributes:nil error:&error];
    
    return [keyStoreDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.key", assetId.hexedMD5]];
}

-(NSData*)loadPersistentContentKeyForAsset:(NSString*)assetId error:(NSError**)error {
    
    NSURL* url = [self contentKeyFileURLForAsset:assetId];
    
    return [NSData dataWithContentsOfURL:url options:0 error:error];
}

-(BOOL)savePersistentContentKey:(NSData*)key forAsset:(NSString*)assetId error:(NSError**)error {
    NSURL* url = [self contentKeyFileURLForAsset:assetId];
    return [key writeToURL:url options:NSDataWritingAtomic error:error];
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)resourceLoadingRequest {

    NSURL *url = resourceLoadingRequest.request.URL;
    NSError *error = nil;
    
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
        return YES;
    }
    
    
    NSTimeInterval expiryDuration = 0.0;
    
    // Check if this reuqest is the result of a potential AVAssetDownloadTask.
    BOOL shouldPersist = resourceLoader.preloadsEligibleContentKeys;
    if (shouldPersist) {
        if (resourceLoadingRequest.contentInformationRequest != nil) {
            resourceLoadingRequest.contentInformationRequest.contentType = AVStreamingKeyDeliveryPersistentContentKeyType;
        } else {
            KPLogError(@"Unable to set contentType on contentInformationRequest.");
            error = [NSError errorWithDomain:TAG code:'USCT' userInfo:nil];
            [resourceLoadingRequest finishLoadingWithError:error];
            return YES;
        }
    }
    
    // Check if we have an existing key on disk for this asset.
    NSData* persistentKey = [self loadPersistentContentKeyForAsset:assetId error:&error];
    if (persistentKey) {
        AVAssetResourceLoadingDataRequest* dataRequest = [resourceLoadingRequest dataRequest];
        [dataRequest respondWithData:persistentKey];
        return YES;
    }
    
    // Get SPC
    NSDictionary* resourceLoadingRequestOptions;
    // Check if this reuqest is the result of a potential AVAssetDownloadTask.
    if (shouldPersist) {
        // Since this request is the result of an AVAssetDownloadTask, we configure the options to request a persistent content key from the KSM.
        resourceLoadingRequestOptions = @{AVAssetResourceLoadingRequestStreamingContentKeyRequestRequiresPersistentKey: @YES};
    }
    NSData *spcData = [resourceLoadingRequest streamingContentKeyRequestDataForApp:self.certificate
                                                              contentIdentifier:[assetId dataUsingEncoding:NSUTF8StringEncoding]
                                                                        options:resourceLoadingRequestOptions
                                                                          error:&error];
    

    if (!spcData) {
        KPLogError(@"Unable to get requestBytes. error=%@", error);
        [resourceLoadingRequest finishLoadingWithError:error];
        return YES;
    }
    
    // Send the SPC message to the Key Server.
    NSData *ckcData = [self performLicenseRequest:spcData leaseExpiryDuration:&expiryDuration error:&error];
    
    
    if (ckcData == nil) {
        [resourceLoadingRequest finishLoadingWithError:error];
        return YES;
    }
    
    NSData* contentKeyData;
    
    if (shouldPersist) {
        // Since this request is the result of an AVAssetDownloadTask, we should get the secure persistent content key.

        contentKeyData = [resourceLoadingRequest persistentContentKeyFromKeyVendorResponse:ckcData options:nil error:&error];
        
        if (!contentKeyData) {
            // TODO: handle error
            return YES;
        }
        
        [self savePersistentContentKey:contentKeyData forAsset:assetId error:&error];
        // TODO: handle error
        
    } else {
        contentKeyData = ckcData;
    }

    
    AVAssetResourceLoadingDataRequest *dataRequest = resourceLoadingRequest.dataRequest;
    if (!dataRequest) {
        //TODO: error
        return YES;
    }
    
    // Provide data to the loading request.
    [dataRequest respondWithData:contentKeyData];
    [resourceLoadingRequest finishLoading];    

    
    // Get the CK expiration time from the CKC. This is used to enforce the expiration of the CK.
    if (expiryDuration != 0.0) {
        
        AVAssetResourceLoadingContentInformationRequest *infoRequest = resourceLoadingRequest.contentInformationRequest;
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
            infoRequest.contentLength = ckcData.length;
            infoRequest.byteRangeAccessSupported = NO;
        }
    }
    [resourceLoadingRequest finishLoading]; // Treat the processing of the request as complete.
    
    
    return YES;
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
