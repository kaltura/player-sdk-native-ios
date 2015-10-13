//
//  DRMHandler.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/19/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#if !(TARGET_IPHONE_SIMULATOR)
#import <Foundation/Foundation.h>

#define KPWVDRMServerKey @"WVDRMServerKey"
#define KPWVPortalKey @"WVPortalKey"

typedef enum KPWViOsApiStatus {
    KPWViOsApiStatus_OK = 0,
    KPWViOsApiStatus_NotInitialized,
    KPWViOsApiStatus_AlreadyInitialized,
    KPWViOsApiStatus_CantConnectToMediaServer,
    KPWViOsApiStatus_BadMedia,
    KPWViOsApiStatus_CantConnectToDrmServer,
    KPWViOsApiStatus_NotEntitled,
    KPWViOsApiStatus_EntitlementDenied,
    KPWViOsApiStatus_LostConnection,
    KPWViOsApiStatus_EntitlementExpired,
    KPWViOsApiStatus_NotEntitledByRegion,
    KPWViOsApiStatus_BadUrl,
    KPWViOsApiStatus_FileNotPresent,
    KPWViOsApiStatus_NotRegistered,
    KPWViOsApiStatus_AlreadyRegistered,
    KPWViOsApiStatus_NotPlaying,
    KPWViOsApiStatus_AlreadyPlaying,
    KPWViOsApiStatus_FileSystemError,
    KPWViOsApiStatus_AssetDBWasCorrupted,
    KPWViOsApiStatus_JailBreakDetected,
    KPWViOsApiStatus_UnknownError,
    
} KPWViOsApiStatus;

typedef enum KPWViOsApiEvent {
    KPWViOsApiEvent_NullEvent = 0,
    KPWViOsApiEvent_EMMReceived,
    KPWViOsApiEvent_EMMFailed,
    KPWViOsApiEvent_Playing,
    KPWViOsApiEvent_PlayFailed,
    KPWViOsApiEvent_Stopped,
    KPWViOsApiEvent_QueryStatus,
    KPWViOsApiEvent_EndOfList,
    KPWViOsApiEvent_Initialized,
    KPWViOsApiEvent_InitializeFailed,
    KPWViOsApiEvent_Terminated,
    KPWViOsApiEvent_EMMRemoved,
    KPWViOsApiEvent_Registered,
    KPWViOsApiEvent_Unregistered,
    KPWViOsApiEvent_SetCurrentBitrate,
    KPWViOsApiEvent_Bitrates,
    KPWViOsApiEvent_ChapterTitle,
    KPWViOsApiEvent_ChapterImage,
    KPWViOsApiEvent_ChapterSetup,
    KPWViOsApiEvent_StoppingOnError,
    KPWViOsApiEvent_VideoParams,
    KPWViOsApiEvent_AudioParams,
    KPWViOsApiEvent_Subtitles,
    KPWViOsApiEvent_AudioOnlyTracks,
} KPWViOsApiEvent;

typedef KPWViOsApiStatus (*KPWViOsApiStatusCallback)( KPWViOsApiEvent event, NSDictionary *attributes );

@protocol KPWViPhoneAPI <NSObject>

KPWViOsApiStatus WV_Initialize(const KPWViOsApiStatusCallback callback, NSDictionary *settings );
KPWViOsApiStatus WV_Play (NSString *asset, NSMutableString *url, NSData *authentication );
KPWViOsApiStatus WV_Stop ();
NSString *NSStringFromWViOsApiEvent( KPWViOsApiEvent );

@end

@interface DRMHandler : NSObject

+ (void)DRMSource:(NSString *)src key:(NSString *)key completion:(void(^)(NSString *DRMLink))completion;
@end
#endif
