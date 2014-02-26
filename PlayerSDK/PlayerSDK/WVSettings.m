//
//  WVSettings.m
//  Kaltura
//
//  Created by Eliza Sapir on 6/3/13.
//
//

#import "WVSettings.h"
#import "WViPhoneAPI.h"

@implementation WVSettings

@synthesize drmServer, portalId;

-(BOOL) isNativeAdapting{
    return nativeAdapting;
}

-(NSDictionary*) initializeDictionary:(NSString *)src andKS: (NSString*) key{
    self.portalId = @"kaltura";

    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                key, WVDRMServerKey,
                                self.portalId, WVPortalKey,
                                NULL];
    
    return dictionary;
}

@end
