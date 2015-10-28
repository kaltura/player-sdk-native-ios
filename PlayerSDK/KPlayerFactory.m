//
//  KPlayerManager.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 3/16/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KPlayerFactory.h"
#import "KDRMManager.h"
#import "KPLog.h"
#import "NSString+Utilities.h"

@interface KPlayerFactory() <KPlayerDelegate>{
    NSString *key;
    BOOL isSeeked;
}

@property (nonatomic, strong) UIViewController *parentViewController;
@property (nonatomic) BOOL contentEnded;
@end

@implementation KPlayerFactory

- (instancetype)initWithPlayerClassName:(NSString *)className {
    self = [super init];
    if (self) {
        self.playerClassName = className;
        return self;
    }
    return nil;
}


- (void)addPlayerToController:(UIViewController *)parentViewController {
    _parentViewController = parentViewController;
    if (!self.player) {
        KPLogError(@"%@", @"NO PLAYER CREATED");
    }
}

- (id<KPlayer>)player {
    if (!_player) {
        Class class = NSClassFromString(_playerClassName);
        _player = [(id<KPlayer>)[class alloc] initWithParentView:_parentViewController.view];
        _player.delegate = self;
    }
    return _player;
}

- (NSString *)getMimeType:(NSURL * )mediaUrl {
    __block NSString *mimeType = nil;
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:mediaUrl]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               mimeType = [response MIMEType];
                           }];
    return mimeType;
}

- (void)setSrc:(NSString *)src {
    // origin src should be saved
    _src = src;
    
    if (![self.player setPlayerSource:[NSURL URLWithString:src]]) {
        [self setDRMSource:nil];
    }
}

- (void)setDRMSource: (NSString *)drmKey {
    if (drmKey) {
        self.drmParams = @{
                                     @"WVDRMServerKey": drmKey,
                                     @"WVPortalKey": WVPortalKey
                                     };
    }
    if (self.drmParams != nil) {
#if !(TARGET_IPHONE_SIMULATOR)
        [KDRMManager DRMSource:self.src
                           key:self.drmParams
                    completion:^(NSString *drmUrl) {
                        if (drmUrl &&
                            ![self.player setPlayerSource:[NSURL URLWithString:drmUrl]]) {
                            KPLogError(@"Media Source is not playable!");
                        }
                    }];
#endif
    }
}

- (void)setCurrentPlayBackTime:(NSTimeInterval)currentPlayBackTime {
    _player.currentPlaybackTime = currentPlayBackTime;
}

- (void)setAdTagURL:(NSString *)adTagURL {
    if (!_adController) {
        _adController = [KPIMAPlayerViewController new];
        if (!_adController) {
            return;
        }
        _adController.adPlayerHeight = _adPlayerHeight;
        _adController.locale = _locale;
        [_parentViewController addChildViewController:_adController];
        [_parentViewController.view addSubview:_adController.view];
        _adController.datasource = _kIMAWebOpenerDelegate;
        __weak KPlayerFactory *weakSelf = self;
        [_adController loadIMAAd:adTagURL
               withContentPlayer:_player
                  eventsListener:^(NSDictionary *adEventParams) {
                      if (adEventParams) {
                          [weakSelf.player.delegate player:weakSelf.player
                                                 eventName:adEventParams.allKeys.firstObject
                                                      JSON:adEventParams.allValues.firstObject];
                      } else if (weakSelf.contentEnded){
                          [weakSelf.delegate allAdsCompleted];
                      } else if (!adEventParams) {
                          [weakSelf.adController removeIMAPlayer];
                          weakSelf.adController = nil;
                      }
                  }];
    }
}


- (void)switchPlayer:(NSString *)playerClassName key:(NSString *)_key {
    _playerClassName = playerClassName;
    key = _key;
}

- (id<KPlayer>)createPlayerFromClassName:(NSString *)className {
    if (className) {
        Class class = NSClassFromString(className);
        
        return [(id<KPlayer>)[class alloc] initWithParentView:_parentViewController.view];
    }
    
    return nil;
}

- (void)changePlayer:(id<KPlayer>)player {
    player.delegate = _player.delegate;
    player.playerSource = _player.playerSource;
    player.duration = _player.duration;
    player.currentPlaybackTime = _player.currentPlaybackTime;
    [self removePlayer];
    _player = player;
}

- (void)changeSubtitleLanguage:(NSString *)isoCode {
    [_player changeSubtitleLanguage:isoCode];
}

- (void)removePlayer {
    if (_adController) {
        [_adController removeIMAPlayer];
    }
    [_player removePlayer];
    _player = nil;
    
    _adController = nil;
}


#pragma mark KPlayerEventsDelegate
- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event value:(NSString *)value {
    [_delegate player:currentPlayer eventName:event value:value];
}

- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event JSON:(NSString *)jsonString {
    [_delegate player:currentPlayer eventName:event JSON:jsonString];
}

- (void)contentCompleted:(id<KPlayer>)currentPlayer {
    self.contentEnded = YES;
    [_adController contentCompleted];
}

- (void)dealloc {
    KPLogInfo(@"Dealloc");
}

@end
