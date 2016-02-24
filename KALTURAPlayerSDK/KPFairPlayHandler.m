//
//  FairPlayHandler.m
//  KALTURAPlayerSDK
//
//  Created by Noam Tamim on 22/02/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import "KPFairPlayHandler.h"

NSString* const URL_SCHEME_NAME = @"skd";

#define CERTIFICATE_URL     @"https://208.185.60.221/viacom.cer"
#define LICENSE_URL         @"http://192.168.162.49:8002/udrm/fps/license?signature=pY64NTYI182vv31jz8uWdGqFW1s%3D&custom_data=eyJjYV9zeXN0ZW0iOiJPVlAiLCJ1c2VyX3Rva2VuIjoiWkRJeVpEWmxZelJqTURFM1pqWXpPRGRtT0RjNE1tVXlNREE1T1RNeE1URmpNamxqTTJKbE9Id3hNREU3TVRBeE96RXdNVFExTVRrNU1UUTNNanN5T3pFME5URTVPVEUwTnpNdU5qUXdNVHRoWkcxcGJqdGthWE5oWW14bFpXNTBhWFJzWlcxbGJuUTdPdz09IiwiYWNjb3VudF9pZCI6IjEwMSIsImNvbnRlbnRfaWQiOiIwX3R1Zmx6MG4zIiwiZmlsZXMiOiIwX3dmYjZ2MHkxIn0%3D"


@interface KPFairPlayHandler () {
    kLicenseUriProvider _licenseUriProvider;
    NSString* _licenseUri;
}
@end

static dispatch_queue_t	globalNotificationQueue( void )
{
    static dispatch_queue_t globalQueue = 0;
    static dispatch_once_t getQueueOnce = 0;
    dispatch_once(&getQueueOnce, ^{
        globalQueue = dispatch_queue_create("tester notify queue", NULL);
    });
    return globalQueue;
}



@implementation KPFairPlayHandler

-(void)attachToAsset:(AVURLAsset *)asset {
    [asset.resourceLoader setDelegate:self queue:globalNotificationQueue()];
}

-(void)setLicenseUri:(NSString*)licenseUri {
    _licenseUri = licenseUri;
}

- (NSData *)loadCertificate {
    static NSData *certificate = nil;
    
    NSError* error;
    if (!certificate) {
        certificate = [NSData dataWithContentsOfURL:[NSURL URLWithString:CERTIFICATE_URL] options:0 error:&error];
        // TODO: errors
    }
    
    return certificate;
}

- (NSData *)getContentKeyAndLeaseExpiryfromKeyServerModuleWithRequest:(NSData *)requestBytes contentIdentifierHost:(NSString *)assetStr leaseExpiryDuration:(NSTimeInterval *)expiryDuration error:(NSError **)errorOut {
    NSData *decodedData = nil;
    
    if (!_licenseUriProvider) {
        // TODO: error
        return nil;
    }
    NSString* licenseUri = _licenseUriProvider(assetStr);
    
    NSURL* reqUrl = [NSURL URLWithString:licenseUri];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:reqUrl];
    request.HTTPMethod=@"POST";
    //    request.HTTPBody=[requestBytes base64EncodedDataWithOptions:0];
    request.HTTPBody=requestBytes;
    [request setValue:@"application/javascript" forHTTPHeaderField:@"Content-Type"];
    
    NSHTTPURLResponse* response = nil;
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:errorOut];
    
    decodedData = [[NSData alloc] initWithBase64EncodedData:responseData options:0];
    
    *expiryDuration = 1000;
    
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
    if (![[url scheme] isEqual:URL_SCHEME_NAME])
        return NO;
    
    NSLog( @"shouldWaitForLoadingOfURLRequest got %@", loadingRequest);
    
    NSString *assetStr;
    NSData *assetId;
    NSData *requestBytes;
    
    assetStr = @"123";
    assetId = [NSData dataWithBytes: [assetStr cStringUsingEncoding:NSUTF8StringEncoding] length:[assetStr lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    
    NSData *certificate = [self loadCertificate];
    
    
    // Get SPC
    requestBytes = [loadingRequest streamingContentKeyRequestDataForApp:certificate
                                                      contentIdentifier:assetId
                                                                options:nil
                                                                  error:&error];
    
    
    NSData *responseData = nil;
    NSTimeInterval expiryDuration = 0.0;
    
    // Send the SPC message to the Key Server.
    responseData = [self getContentKeyAndLeaseExpiryfromKeyServerModuleWithRequest:requestBytes
                                                             contentIdentifierHost:assetStr
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
