//
//  TVMediaToPlayInfo.h
//  YES_iPad
//
//  Created by Rivka S. Peleg on 10/22/13.
//  Copyright (c) 2013 Alexander Israel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TVCDeclerations.h"

@interface TVMediaToPlayInfo : NSObject
/**
 *	Media To play
 */
@property (retain, nonatomic) TVMediaItem * mediaItem;

/**
 *	The movie should seek to this time as first 
 */
@property (assign, nonatomic) float startTime; // in ....

/**
 *	file key of the type of file in media files to play for example: main file , trailer , main file RU etc'
 */
@property (retain, nonatomic) NSString * fileTypeFormatKey;

/**
 *	file key of the playback mode, usually set YES to .mp4 formats.
 */
@property (readwrite, assign) BOOL isProgressiveDownload;

#pragma mark - Custom Properties

/**
 *	isSignedUrl - Bool value that determines if the final URL should be licensed or as it is, and finally will be sent to the player.
 */
@property (nonatomic, assign) BOOL useSignedUrl;

/**
 *	isHarmonicsHLS - Bool value that determines if the media is an HLS harmonics format.
 */
@property (nonatomic, assign) BOOL isHarmonicsHLS;

/**
 *	customData - String value, for rights acqisition in a playReady encrypted stream.
 */
@property (retain, nonatomic) NSString* customData;

/**
 *	isClearContent - Bool value that determines if the media is a clear content (not encrypted).
 */
@property (nonatomic, assign) BOOL isClearContent;


/**
 * when recorded asset is played all media hit and media mark need to be sent with the record id and not with the file id.
 */
@property (nonatomic, strong) NSString * npvrId;


#pragma mark - For Start Over

/**
 *	- addPLTVFileWithFormat - returns void.
 *      add a new PLTV file to mediaToPlay object, such as TVCMediaFormat_CatchUp, TVCMediaFormat_StartOver, TVCMediaFormat_PauseAndPlay, etc...
        return YES if all given parameters are valid, otherwise NO.
 */
- (BOOL)addPLTVFileWithFormat:(NSString *)format andUrlString:(NSString *)pltvUrl andBaseFile:(TVFile *)baseFile;

- (TVFile *)currentFile;


- (id)initWithMediaItem:(TVMediaItem *)mediaItem;

#pragma mark - Constants for the Media Format types

extern NSString * const TVCMediaFormat_Main;
extern NSString * const TVCMediaFormat_Trailer;
extern NSString * const TVCMediaFormat_TabletMain;
extern NSString * const TVCMediaFormat_TabletTrailer;
extern NSString * const TVCMediaFormat_SmartphoneMain;
extern NSString * const TVCMediaFormat_SmartphoneTrailer;
extern NSString * const TVCMediaFormat_MobileDevicesMainHD;
extern NSString * const TVCMediaFormat_MobileDevicesMainSD;
extern NSString * const TVCMediaFormat_MobileDevicesTrailer;
extern NSString * const TVCMediaFormat_CatchUp;
extern NSString * const TVCMediaFormat_StartOver;
extern NSString * const TVCMediaFormat_PauseAndPlay;
extern NSString * const TVCMediaFormat_TrickPlay;
@end

