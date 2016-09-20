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

+(dispatch_queue_t)globalNotificationQueue {
    static dispatch_queue_t globalQueue = 0;
    static dispatch_once_t getQueueOnce = 0;
    dispatch_once(&getQueueOnce, ^{
        globalQueue = dispatch_queue_create("fairplay notify queue", NULL);
    });
    return globalQueue;
}

- (NSData *)performLicenseRequest:(NSData *)requestBytes error:(NSError **)error {
    
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
    
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
    
    licenseResponseTime = [NSDate timeIntervalSinceReferenceDate] - licenseResponseTime;
    KPLogDebug(@"Received license response (%.3f)", licenseResponseTime);
    
    if (!responseData) {
        KPLogError(@"No license response, error=%@", *error);
        return nil;
    }
    
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:error];
    if (!dict) {
        KPLogError(@"Invalid license response, error=%@", *error);
        return nil;
    }
    
    NSString* errMessage = dict[@"message"];
    if (errMessage) {
        *error = [NSError errorWithDomain:TAG code:'CKCE' userInfo:@{@"ServerMessage": errMessage}];
        KPLogError(@"Error message from license server: %@", errMessage);
        return nil;
    }
    NSString* ckc = dict[@"ckc"];

    if (!ckc) {
        *error = [NSError errorWithDomain:TAG code:'NCKC' userInfo:nil];
        KPLogError(@"No CKC in license response");
        return nil;
    }
    
    NSData* ckcData = [[NSData alloc] initWithBase64EncodedString:ckc options:0];
    
    if (![ckcData length]) {
        *error = [NSError errorWithDomain:TAG code:'ICKC' userInfo:nil];
        KPLogError(@"Invalid CKC in license response");
        return nil;
    }
        
    return ckcData;
}


-(NSURL*)contentKeyLocationForAsset:(NSString*)assetId error:(NSError**)error {

    NSURL* libraryDir = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:error];
    
    if (!libraryDir) {
        return nil;
    }   
    
    NSURL* keyStoreDir = [libraryDir URLByAppendingPathComponent:@"KalturaKeyStore" isDirectory:YES];
    if (![[NSFileManager defaultManager] createDirectoryAtURL:keyStoreDir withIntermediateDirectories:YES attributes:nil error:error]) {
        return nil;
    }
    
    return [keyStoreDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.key", assetId.hexedMD5]];
}

-(NSData*)loadPersistentContentKeyForAsset:(NSString*)assetId error:(NSError**)error {
    
    NSURL* url = [self contentKeyLocationForAsset:assetId error:error];
    if (!url) {
        KPLogError(@"Can't get contentkey location. Error: %@", *error);
        return nil;
    }
    
    NSError* readError;
    NSData* data = [NSData dataWithContentsOfURL:url options:0 error:&readError];
    
    if (!data) {
        if (readError.domain != NSCocoaErrorDomain || readError.code != NSFileReadNoSuchFileError) {
            // NSFileReadNoSuchFileError is expected in this context; something else is more serious.
            *error = readError;
        }
    }
    
    return data;
}

-(BOOL)savePersistentContentKey:(NSData*)key forAsset:(NSString*)assetId error:(NSError**)error {
    NSURL* url = [self contentKeyLocationForAsset:assetId error:error];
    if (!url) {
        return NO;
    }
    return [key writeToURL:url options:NSDataWritingAtomic error:error];
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)resourceLoadingRequest {
    
    NSURL* url = resourceLoadingRequest.request.URL;
    if (![url.scheme isEqual:SKD_URL_SCHEME_NAME]) {
        return NO;
    }
    
    [self handleFairPlayLicenseRequest:resourceLoadingRequest resourceLoader:resourceLoader asset:url.host];
    
    return YES; // we answer yes regardless of success/failure, because we handled the request.

}

-(void)waitForDrmParams {
    // Wait for licenseUri and certificate, up to 5 seconds. In particular, the certificate might not be ready yet.
    // TODO: a better way of doing it is semaphores of some kind. 
    for (int i=0; i < 5*1000/50 && !(_certificate && _licenseUri); i++) {
        struct timespec delay;
        delay.tv_nsec = 50*1000*1000; // 50 millisec
        delay.tv_sec = 0;
        nanosleep(&delay, &delay);
    }
}

-(void)handleFairPlayLicenseRequest:(AVAssetResourceLoadingRequest *)resourceLoadingRequest resourceLoader:(AVAssetResourceLoader *)resourceLoader asset:(NSString*)assetId {

    NSError *error = nil;
    
    // Check if this reuqest is the result of a potential AVAssetDownloadTask.
    BOOL shouldPersist = resourceLoader.preloadsEligibleContentKeys;
    if (shouldPersist) {
        if (resourceLoadingRequest.contentInformationRequest != nil) {
            resourceLoadingRequest.contentInformationRequest.contentType = AVStreamingKeyDeliveryPersistentContentKeyType;
        } else {
            KPLogError(@"Unable to set contentType on contentInformationRequest.");
            error = [NSError errorWithDomain:TAG code:'USCT' userInfo:nil];
            [resourceLoadingRequest finishLoadingWithError:error];
            return;
        }
    }
    
    // Check if we have an existing key on disk for this asset.
    NSData* persistentKey = [self loadPersistentContentKeyForAsset:assetId error:&error];
    if (persistentKey) {
        // We're done.
        AVAssetResourceLoadingDataRequest* dataRequest = [resourceLoadingRequest dataRequest];
        [dataRequest respondWithData:persistentKey];
        [resourceLoadingRequest finishLoading];
        return;

    } else if (error) {
        KPLogError(@"Error loading persisted content key; failing the request with error: %@", error);
        [resourceLoadingRequest finishLoadingWithError:error];
        return;
    }

    [self waitForDrmParams];
    
    if (!self.certificate) {
        KPLogError(@"Certificate is invalid or not set, can't continue");
        error = [NSError errorWithDomain:TAG code:'ICRT' userInfo:nil];
        [resourceLoadingRequest finishLoadingWithError:error];
        return;
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
        return;
    }
    
    // Send the SPC message to the Key Server.
    NSData *ckcData = [self performLicenseRequest:spcData error:&error];
    
    
    if (ckcData == nil) {
        [resourceLoadingRequest finishLoadingWithError:error];
        return;
    }
    
    NSData* contentKeyData;
    
    if (shouldPersist) {
        // Since this request is the result of an AVAssetDownloadTask, we should get the secure persistent content key.

        contentKeyData = [resourceLoadingRequest persistentContentKeyFromKeyVendorResponse:ckcData options:nil error:&error];
        
        if (!contentKeyData) {
            KPLogError(@"Unable to get persistent content key. error=%@", error);
            [resourceLoadingRequest finishLoadingWithError:error];
            return;
        }
        
        if (![self savePersistentContentKey:contentKeyData forAsset:assetId error:&error]) {
            KPLogError(@"Unable to save persistent content key. error=%@", error);
            [resourceLoadingRequest finishLoadingWithError:error];
            return;
        }
        
    } else {
        contentKeyData = ckcData;
    }

    
    AVAssetResourceLoadingDataRequest *dataRequest = resourceLoadingRequest.dataRequest;
    if (!dataRequest) {
        // This is not very likely to happen.
        KPLogError(@"Can't get resourceLoadingRequest.dataRequest");
        error = [NSError errorWithDomain:TAG code:'NRDR' userInfo:nil];
        [resourceLoadingRequest finishLoadingWithError:error];
        return;
    }
    
    // Provide data to the loading request.
    [dataRequest respondWithData:contentKeyData];
    [resourceLoadingRequest finishLoading];    
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
