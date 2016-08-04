//
//  NSMutableDictionary+AdSupport.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 1/19/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *AdLoadedEventKey = @"adLoadedEvent";
static NSString *AdLoadedKey = @"adLoaded";
static NSString *AdStartKey = @"adStart";
static NSString *AdCompletedKey = @"adCompleted";
static NSString *AllAdsCompletedKey = @"allAdsCompleted";
static NSString *ContentPauseRequestedKey = @"contentPauseRequested";
static NSString *ContentResumeRequestedKey = @"contentResumeRequested";
static NSString *FirstQuartileKey = @"firstQuartile";
static NSString *MidPointKey = @"midpoint";
static NSString *ThirdQuartileKey = @"thirdQuartile";
static NSString *AdRemainingTimeChangeKey = @"adRemainingTimeChange";
static NSString *AdClickedKey = @"adClicked";
static NSString *AdSkippeddKey = @"adSkipped";
static NSString *AdsLoadErrorKey = @"adsLoadError";
static NSString *AdsSupportEndAdPlaybackKey = @"AdSupport_EndAdPlayback";
static NSString *CastingKey = @"casting";



@interface NSMutableDictionary (AdSupport)
@property (nonatomic, assign) BOOL isLinear;
@property (nonatomic, copy) NSString *adID;
@property (nonatomic, copy) NSString *adSystem;
@property (nonatomic, assign) int adPosition;
@property (nonatomic, copy) NSString *context;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval time;
@property (nonatomic, assign) NSTimeInterval remain;

@property (nonatomic, copy, readonly) NSString *toJSON;
@end
