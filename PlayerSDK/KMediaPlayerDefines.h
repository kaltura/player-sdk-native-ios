//
//  KMediaPlayerDefines.h
//  KALTURAPlayerSDK
//
//  Created by Eliza Sapir on 7/8/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#ifdef __cplusplus
#define KP_EXTERN extern "C" __attribute__((visibility ("default")))
#else
#define KP_EXTERN     extern __attribute__((visibility ("default")))
#endif

#define KP_EXTERN_CLASS                    __attribute__((visibility("default")))
#define KP_EXTERN_CLASS_AVAILABLE(version) __attribute__((visibility("default"))) NS_CLASS_AVAILABLE(NA, version)
