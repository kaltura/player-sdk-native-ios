//
//  KChromecastPlayer.h
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 02/06/2016.
//  Copyright © 2016 Kaltura. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KChromeCastWrapper.h"

@protocol KChromecastPlayerDelegate <NSObject>

- (void)updateProgress:(NSTimeInterval)currentTime;
- (void)readyToPlay:(id<KPGCMediaControlChannel>)mediaControlChannel;
- (void)castPlayerState:(NSString *)state;

@end

@interface KChromecastPlayer : NSObject
- (instancetype)initWithMediaChannel:(id<KPGCMediaControlChannel>)mediaChannel;
@property (nonatomic, weak) id<KChromecastPlayerDelegate> delegate;
@property (nonatomic) NSTimeInterval currentTime;

- (void)play;
- (void)pause;
- (void)seek:(NSTimeInterval)time;

- (void)setVideoUrl:(NSString *)videoUrl
      startPosition:(NSTimeInterval)startPosition;

@end
