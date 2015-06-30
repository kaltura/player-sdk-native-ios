//
//  TVMediaToPlayInfo.m
//  YES_iPad
//
//  Created by Rivka S. Peleg on 10/22/13.
//  Copyright (c) 2013 Alexander Israel. All rights reserved.
//

#import "TVMediaToPlayInfo.h"


@interface TVMediaToPlayInfo () {
    
}

@property (nonatomic, retain) NSMutableDictionary* filesDataSource;

@end

@implementation TVMediaToPlayInfo
@synthesize useSignedUrl;
@synthesize customData;
@synthesize isHarmonicsHLS;
@synthesize isClearContent;

- (id)initWithMediaItem:(TVMediaItem *)mediaItem
{
    self = [super init];
    if (self) {
        self.mediaItem = mediaItem;
        [self setup];
    }
    return self;
}

- (void)setup {

    self.filesDataSource = [[NSMutableDictionary alloc] init] ;
    for (TVFile* file in self.mediaItem.files) {
        [self.filesDataSource setObjectOrNil:file forKey:file.format];
    }
}

-(void)dealloc {
    self.filesDataSource = nil;
    self.mediaItem = nil;
}

- (BOOL)addPLTVFileWithFormat:(NSString *)format andUrlString:(NSString *)pltvUrl andBaseFile:(TVFile *)baseFile {
    if (!baseFile || !format || !pltvUrl) {
        return NO;
    }
    TVFile * newFile        = [baseFile copy];
    newFile.fileURL         = [NSURL URLWithString:pltvUrl];
    newFile.format = format;
    [self.filesDataSource setObjectOrNil:newFile forKey:format];
    return YES;
}

- (TVFile *)currentFile {
    return [self.filesDataSource objectOrNilForKey:self.fileTypeFormatKey];
}


@end


#pragma mark - Constants for the Media Format types
NSString * const TVCMediaFormat_Main = @"Main";
NSString * const TVCMediaFormat_Trailer = @"Trailer";
NSString * const TVCMediaFormat_TabletMain = @"Tablet Main";
NSString * const TVCMediaFormat_TabletTrailer = @"Tablet Trailer";
NSString * const TVCMediaFormat_SmartphoneMain = @"Smartphone Main";
NSString * const TVCMediaFormat_SmartphoneTrailer = @"Smarthpone Trailer";
NSString * const TVCMediaFormat_MobileDevicesMainHD = @"Mobile Devices Main HD";
NSString * const TVCMediaFormat_MobileDevicesMainSD = @"Mobile Devices Main SD";
NSString * const TVCMediaFormat_MobileDevicesTrailer = @"Mobile Devices Trailer";

NSString * const TVCMediaFormat_CatchUp = @"TVCMediaFormat_CatchUp";
NSString * const TVCMediaFormat_StartOver = @"TVCMediaFormat_StartOver";
NSString * const TVCMediaFormat_PauseAndPlay = @"TVCMediaFormat_PauseAndPlay";
NSString * const TVCMediaFormat_TrickPlay = @"TVCMediaFormat_TrickPlay";

