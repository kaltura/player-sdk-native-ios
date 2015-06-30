//
//  TVCDeclerations.h
//  TVCPlayerStaticLibrary
//
//  Created by Tarek Issa on 10/7/13.
//  Copyright (c) 2013 Tvinci. All rights reserved.
//

#ifndef TVCPlayerStaticLibrary_TVCDeclerations_h
#define TVCPlayerStaticLibrary_TVCDeclerations_h

#import <UIKit/UIKit.h>
#import <TvinciSDK/TvinciSDK.h>
@class TVCplayer;
@class TVMediaToPlayInfo;


#pragma typedef enums

typedef enum {
    TVCDrmStatus_OK,
    TVCDrmStatusPersonalization_Failed, //  DRM error
    TVCDrmStatusDownloadContent_Failed, //  DRM error
    TVCDrmStatusIsDRM_Failed, //  DRM error
    TVCDrmStatusAquireRights_Failed, //  DRM error
    TVCDrmStatus_Interrupted,
    TVCDrmStatus_IncorrectFileUrl,
    TVCDrmStatus_IncorrectMediaItemOrNull,
    TVCDrmStatus_IncorrectLicensedURL,
    TVCDrmStatus_DeviceNotSecured,
    TVCDrmStatus_UNKNOWN
    
} TVCDrmStatus;

typedef enum
{
    TVAudioLanguage_DEFAULT,
    TVAudioLanguage_HE,
    TVAudioLanguage_EN,
    TVAudioLanguage_RU
    
}TVAudioLanguage;

typedef enum {
    TVCSubsLan_HE,
    TVCSubsLan_EN,
    TVCSubsLan_RU
} TVCSubsLan;

typedef struct {
    int hours;
    int minutes;
    int seconds;
    
} TimeStruct;

typedef enum {
    TVPPlaybackStateIsPlaying,
    TVPPlaybackStatePasued,
    TVPPlaybackStateStopped,
    TVPPlaybackStateReady,
    TVPPlaybackStateUnknown
} TVPPlaybackState;



typedef enum {
  TVPMovieLoadStateUnknown              = 0,
  TVPMovieLoadStatePlayable             = 1 << 0,
  TVPMovieLoadStatePlaythroughOK        = 1 << 1,
  TVPMovieLoadStateStalled              = 1 << 2,
} TVPMovieLoadState;



typedef enum {
    TVDRMTypeNone,
    TVDRMTypeWidevine,
    TVDRMTypePlayready,
    TVDRMTypeClear
} TVDRMType;

#pragma protocols

@protocol TVCPlayerSubtitlesProtocol <NSObject>
- (NSArray*)parseSubtitleString:(NSString*)stringToParse;
@end

@protocol TVCplayerStatusProtocol <NSObject>
@optional

/*   Mandatory for using the player, here probably you will send Play message to the Player after switchToMediaItem.   */
- (void)movieShouldStartPlayingWithMediaItem:(TVMediaItem*)mediaItem atPlayer:(TVCplayer*)player;

/*   Triggered whenever something got wrong in the pre-processing of the media.   */
- (void)movieProcessFailedWithStatusError:(TVCDrmStatus)status withMediaItem:(TVMediaItem*)mediaItem atPlayer:(TVCplayer*)player;

/*  Media has reached to end    */
- (void)movieFinishedPresentationWithMediaItem:(TVMediaItem*)mediaItem atPlayer:(TVCplayer*)player;

/*  Movie player is buffering stream    */
- (void)movieIsBufferingForMediaItem:(TVMediaItem*)mediaItem;

/*  Movie player has enough buffer for playback    */
- (void)movieHasFinishedBufferingForMediaItem:(TVMediaItem*)mediaItem;

/*  Bitrate Changed    */
- (void)moviePlaybackBitrateChangedFor:(TVMediaItem*)mediaItem withNewBitrate:(int)bitrate outOfBitratesArr:(NSArray*)bitratesArr;

/*  Monitors playback every one second */
- (void)monitorPlaybackTime __attribute__((deprecated));

/*  Monitors playback every one second */
- (void)monitorPlaybackTimeAtPlayer:(TVCplayer*)player;

- (void)monitorMediaLocation:(CGFloat) currentLocation;

/*   Mandatory for using the player, here probably you will send Play message to the Player after switchToMediaItem.   */
- (void)playerDetectedConcurrentWithMediaItem:(TVMediaItem*)mediaItem atPlayer:(TVCplayer*)player;

/* player sometimes failes during playing end sending errors */
-(void) player:(TVCplayer *) player didDetectError:(NSDictionary*) info;

-(void) playerDetectHeadPhpnesPullOut:(TVCplayer *) player;

-(void) playerDetectTimeOut:(TVCplayer *) player;

-(BOOL) player:(TVCplayer *) player shouldAutoPlayForMediaItemToPlay:(TVMediaToPlayInfo *) mediaItemToPlay;

-(void) player:(TVCplayer *)player didOpenFileOfMediaToPlay:(TVMediaToPlayInfo *) mediaItemToPlay;


@end

@protocol TVCPlayerProtocol <NSObject>
@optional
/*  Returns playaback duration in <ms>*/
- (float)getPlaybackDuration;

/*  Returns playaback position in <ms>*/
- (float)getCurrentPlaybackTime;

/*  Returns playaback position in <sec>*/
- (float)getCurrentPlaybackTimeInSeconds;

- (void)setFrame:(CGRect)frame;
- (TimeStruct)getPlaybackDurationInStructFormat;
- (TimeStruct)getCurrentPlaybackInStructFormat;
@end


#endif
