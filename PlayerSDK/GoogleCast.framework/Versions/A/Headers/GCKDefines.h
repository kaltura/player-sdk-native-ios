// Copyright 2014 Google Inc.

#import <Availability.h>

#ifndef GCK_EXPORT
#define GCK_EXPORT __attribute__((visibility("default")))
#endif

#ifndef GCK_EXTERN
#ifdef __cplusplus
#define GCK_EXTERN extern "C" GCK_EXPORT
#else
#define GCK_EXTERN extern GCK_EXPORT
#endif
#endif

#ifndef GCK_DEPRECATED
#define GCK_DEPRECATED __attribute__((deprecated))
#endif
