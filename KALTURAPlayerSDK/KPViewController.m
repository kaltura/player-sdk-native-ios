//
//  KalPlayerViewController.m
//  HelloWorld
//
//  Created by Eliza Sapir on 9/11/13.
//
//

// Copyright (c) 2013 Kaltura, Inc. All rights reserved.
// License: http://corp.kaltura.com/terms-of-use
//

static NSString *AppConfigurationFileName = @"AppConfigurations";

#import "KPViewController.h"
#import "KPShareManager.h"
#import "NSDictionary+Strategy.h"
#import "KPBrowserViewController.h"
#import "NSString+Utilities.h"
#import "DeviceParamsHandler.h"
#import "KPIMAPlayerViewController.h"
#import "KPlayerFactory.h"
#import "KPControlsView.h"
#import "KPController_Private.h"
#import "KPURLProtocol.h"
#import "KCacheManager.h"
#import "NSBundle+Kaltura.h"
#import "NSDictionary+Utilities.h"
#import "KPAssetBuilder.h"
#import "KPPlayerConfig_Private.h"

#include <sys/types.h>
#include <sys/sysctl.h>

typedef NS_ENUM(NSInteger, KPActionType) {
    KPActionTypeShare,
    KPActionTypeOpenHomePage,
    KPActionTypeSkip
};

typedef NS_ENUM(NSInteger, KPError) {
    KPErrorMsg = 500
};

NSString *const KPErrorDomain = @"com.kaltura.player";

@interface KPViewController() <KPlayerFactoryDelegate,
                                KPControlsViewDelegate,
                                UIActionSheetDelegate,
                                KPControllerDelegate> {
    // Player Params
    BOOL isFullScreen, isPlaying, isResumePlayer;
    BOOL _activatedFromBackground;
    NSDictionary *appConfigDict;
    BOOL isCloseFullScreenByTap;
    BOOL isJsCallbackReady;
    NSDictionary *nativeActionParams;
    NSMutableArray *callBackReadyRegistrations;
    NSURL *videoURL;
    void(^_shareHandler)(NSDictionary *);
    void (^_seekedEventHandler)();
    void (^_adRemovedEventHandler)();
                                    
    BOOL isActionSheetPresented;
}

@property (nonatomic, strong) id<KPControlsView> controlsView;
@property (nonatomic, copy) NSMutableDictionary *kPlayerEventsDict;
@property (nonatomic, copy) NSMutableDictionary *kPlayerEvaluatedDict;
@property (nonatomic, strong) KPShareManager *shareManager;
@property (nonatomic, strong) KPlayerFactory *playerFactory;
@property (nonatomic) BOOL isModifiedFrame;
@property (nonatomic) BOOL isFullScreenToggled;
@property (nonatomic, strong) UIView *superView;
@property (nonatomic) NSTimeInterval seekValue;

@end

@implementation KPViewController 
@synthesize controlsView;

+ (void)setLogLevel:(KPLogLevel)logLevel {
    @synchronized(self) {
        KPLogManager.KPLogLevel = logLevel;
    }
}


#pragma mark Initialize methods
- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        videoURL = url;
        
        return self;
    }
    return nil;
}

- (instancetype)initWithConfiguration:(KPPlayerConfig *)configuration {
    self = [super init];
    if (self) {        
        _currentConfiguration = configuration;
        _currentConfiguration.supportedMediaFormats = [KPAssetBuilder supportedMediaFormats];
        videoURL = _currentConfiguration.videoURL;

        // If the developer set the cache size, the cache system is triggered.
        if (_currentConfiguration.cacheSize > 0) {
            [KPURLProtocol enable];
            CacheManager.baseURL = configuration.resolvedPlayerURL;
            CacheManager.includePatterns = configuration.cacheConfig.includePatterns;
            CacheManager.maxCacheSize = _currentConfiguration.cacheSize;
        }
        return self;
    }
    return nil;
}


- (void)loadPlayerIntoViewController:(UIViewController *)parentViewController {
    if (parentViewController && [parentViewController isKindOfClass:[UIViewController class]]) {
        _isModifiedFrame = YES;
        [parentViewController addChildViewController:self];
    }
}

- (void)removePlayer {
    [self.controlsView removeControls];
    [self.playerFactory removePlayer];
    [callBackReadyRegistrations removeAllObjects];
    [self.kPlayerEvaluatedDict removeAllObjects];
    [self.kPlayerEventsDict removeAllObjects];
    self.controlsView = nil;
    self.playerFactory = nil;
    callBackReadyRegistrations = nil;
    appConfigDict = nil;
    nativeActionParams = nil;
    videoURL = nil;
    self.kPlayerEvaluatedDict = nil;
    self.kPlayerEventsDict = nil;
    [self removeFromParentViewController];
    
    @try {
        [self.view removeObserver:self forKeyPath:@"frame" context:nil];
    }
    @catch (NSException *exception) {
        KPLogTrace(@"frame not observed");
    }
    
    _delegate = nil;
    _playerController = nil;
    _currentConfiguration = nil;
    _kdpAPIState = KDPAPIStateUnknown;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    _superView = nil;
}

- (void)resetPlayer {
    [self.playerFactory.player pause];
    [self.controlsView reset];
    [self.playerFactory prepareForChangeConfiguration];
}

- (NSTimeInterval)currentPlaybackTime {
    return _playerFactory.player.currentPlaybackTime;
}

- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime {
    if (!_playerFactory) {
        _seekValue = currentPlaybackTime;
    }
    
    _playerFactory.player.currentPlaybackTime = currentPlaybackTime;
}

- (NSTimeInterval)duration {
    return _playerFactory.player.duration;
}

- (float)volume {
    return _playerFactory.player.volume;
}

- (void)setVolume:(float)value {
    _playerFactory.player.volume = value;
}

- (BOOL)mute {
    return _playerFactory.player.isMuted;
}

- (void)setMute:(BOOL)isMute {
    _playerFactory.player.mute = isMute;
}

- (NSURL *)playerSource {
    return _playerFactory.player.playerSource;
}

- (void)setPlayerSource:(NSURL *)playerSource {
    _playerFactory.player.playerSource = playerSource;
}

- (void)setShareHandler:(void (^)(NSDictionary *))shareHandler {
    _shareHandler = shareHandler;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (keyPath.isFrameKeypath) {
        if ([object isEqual:self.view]) {
            [self.view.layer.sublayers.firstObject setFrame:(CGRect){CGPointZero, self.view.frame.size}];
            ((UIView *)self.controlsView).frame = (CGRect){CGPointZero, self.view.frame.size};
        }
    }
}


#pragma mark -
#pragma mark Lazy init
- (NSMutableDictionary *)kPlayerEventsDict {
    
    if (!_kPlayerEventsDict) {
        _kPlayerEventsDict = [NSMutableDictionary new];
    }
    
    return _kPlayerEventsDict;
}

- (NSMutableDictionary *)kPlayerEvaluatedDict {
    
    if (!_kPlayerEvaluatedDict) {
        _kPlayerEvaluatedDict = [NSMutableDictionary new];
    }
    
    return _kPlayerEvaluatedDict;
}

- (NSString *)platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    
    return platform;
}

- (void)releaseAndSavePosition {
    self.playerFactory.isReleasePlayerPositionEnabled = YES; 
    [self.playerController pause];
}

- (void)resumePlayer {
    self.playerFactory.isReleasePlayerPositionEnabled = NO;
    
    if (self.playerFactory.adController) {
        [self.playerFactory.adController resume];
    }
}

- (KPPlayerConfig *)currentConfiguration {
    
    if (!_currentConfiguration) {
        _currentConfiguration = [KPPlayerConfig new];
    }
    
    return _currentConfiguration;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    // Assign ourselves as delegate ONLY in viewWillAppear of a view controller.
    KPLogTrace(@"%@", [NSValue valueWithCGRect:((UIView *)self.controlsView).frame]);
}

#pragma mark -
#pragma mark View flow methods
- (void)viewDidLoad {
    KPLogTrace(@"Enter");
    appConfigDict = extractDictionary(AppConfigurationFileName, @"plist");
    setUserAgent();
    [self initPlayerParams];
    self.controlsView.shouldUpdateLayout = YES;
    // Pinch Gesture Recognizer - Player Enter/ Exit FullScreen mode
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(didPinchInOut:)];
    [self.view addGestureRecognizer:pinch];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationDidEnterBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationDidBecomeActive:)
                                                 name: UIApplicationDidBecomeActiveNotification
                                               object: nil];
    
    [self.view addObserver:self
                forKeyPath:@"frame"
                   options:NSKeyValueObservingOptionNew
                   context:nil];

    // Initialize player factory
    if (!_playerFactory) {
        _playerFactory = [[KPlayerFactory alloc] initWithPlayerClassName:PlayerClassName];
        [_playerFactory addPlayerToController:self];
        _playerFactory.delegate = self;
        _playerFactory.kIMAWebOpenerDelegate = _kIMAWebOpenerDelegate;
    }
    
    // Initialize player controller
    if (!_playerController) {
        _playerController = [KPController new];
        _playerController.delegate = self;
    }
    
    // Initialize HTML layer (controls)
    if (!self.controlsView) {
        self.controlsView = [KPControlsView defaultControlsViewWithFrame:(CGRect){CGPointZero, self.view.frame.size}];
        self.controlsView.controlsDelegate = self;
        [self.controlsView loadRequest:[NSURLRequest requestWithURL:[self.currentConfiguration appendConfiguration:videoURL]]];
        [self.view addSubview:(UIView *)self.controlsView];
        _kdpAPIState = KDPAPIStateUnknown;
    }
    
    // Handle full screen events
    __weak KPViewController *weakSelf = self;
    [self registerReadyEvent:^{
        __strong KPViewController *strongSelf = weakSelf;
        [[NSNotificationCenter defaultCenter] postNotificationName:KPMediaPlaybackStateDidChangeNotification object:strongSelf userInfo:@{KMediaPlaybackStateKey: @(KPMediaPlaybackStateLoaded)}];
        [strongSelf.playerController setPlaybackState:KPMediaPlaybackStateLoaded];
        if (!strongSelf.isModifiedFrame) {
            strongSelf.setKDPAttribute(@"fullScreenBtn", @"visible", @"false");
        } else {
            strongSelf.addEventListener(KPlayerEventToggleFullScreen, @"defaultFS", ^(NSString *eventId, NSString *params) {
                strongSelf.isFullScreenToggled = !self.isFullScreenToggled;
                strongSelf.controlsView.shouldUpdateLayout = YES;
                if (strongSelf.isFullScreenToggled) {
                    strongSelf.view.frame = screenBounds();
                    [strongSelf.topWindow makeKeyAndVisible];
                    [strongSelf.topWindow.rootViewController.view addSubview:strongSelf.view];
                } else {
                    strongSelf.view.frame = strongSelf.superView.bounds;
                    [strongSelf.superView addSubview:strongSelf.view];
                }
            });
        }
    }];
    [super viewDidLoad];
    KPLogTrace(@"Exit");
}

- (void)setCastProvider:(id<KPCastProvider>)castProvider {
    KPLogTrace(@"Enter setCastProvider");
    
    if (self.playerFactory.adController) {
        __weak KPViewController *weakSelf = self;
        [self removeAdPlayerWithCompletion:^{
            __strong KPViewController *strongSelf = weakSelf;
            KPLogTrace(@"AdPlayer was removed");
            strongSelf.playerFactory.castProvider = castProvider;
            [strongSelf triggerCastEvent:castProvider];
        }];
        
        KPLogTrace(@"Exit setCastProvider");
        return;
    }
    
    _playerFactory.castProvider = castProvider;
    [self triggerCastEvent:castProvider];
    
    KPLogTrace(@"Exit setCastProvider");
}

- (void)removeAdPlayerWithCompletion:(void(^)())completion {
    _adRemovedEventHandler = [completion copy];
    
    if (self.playerFactory.adController) {
        [self allAdsCompleted];
        [self.controlsView triggerEvent:CastingKey withJSON:nil];
        __weak KPViewController *weakSelf = self;
        [self addKPlayerEventListener:AdsSupportEndAdPlaybackKey eventID:AdsSupportEndAdPlaybackKey handler:^(NSString *eventName, NSString *params) {
            [weakSelf removeKPlayerEventListener:AdsSupportEndAdPlaybackKey eventID:AdsSupportEndAdPlaybackKey];
            if (_adRemovedEventHandler) {
                KPLogDebug(@"call seekedEventHandler");
                _adRemovedEventHandler();
                _adRemovedEventHandler = nil;
            }
            KPLogTrace(@"AdsSupportEndAdPlaybackKey Fired");
        }];
        [self.playerFactory removeAdController];
    }
    
}

- (void)triggerCastEvent:(id<KPCastProvider>)castProvider {
    if (castProvider && _playerFactory.castProvider.isConnected) {
        [self.controlsView triggerEvent:@"chromecastDeviceConnected" withValue:[NSString stringWithFormat:@"%f", self.currentPlaybackTime]];
    }
}

- (id<KPCastProvider>)castProvider {
    return _playerFactory.castProvider;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_superView) {
        _superView = self.view.superview;
    }
    if (isIOS(7) && _currentConfiguration.supportedInterfaceOrientations != UIInterfaceOrientationMaskAll) {
        [self.view.layer.sublayers.firstObject setFrame:screenBounds()];
        ((UIView *)self.controlsView).frame = screenBounds();
    }
//    [self performSelector:@selector(updateControlsView) withObject:nil afterDelay:1];
}

- (void)viewDidDisappear:(BOOL)animated {
    KPLogTrace(@"Enter");
    isResumePlayer = YES;
    [super viewDidDisappear:animated];
    KPLogTrace(@"Exit");
}

- (void)applicationDidEnterBackground: (NSNotification *)not {
    KPLogTrace(@"Enter");
    
    if (_playerFactory.castProvider.isConnected) {
        return;
    }
    
    _activatedFromBackground = YES;

    if ([NSBundle mainBundle].isAudioBackgroundModesEnabled){
        // support playing media while in the background 
        [self.playerFactory enableTracks:NO];
    } else {
        [self.playerFactory.player pause];
    }

    KPLogTrace(@"Exit");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    KPLogTrace(@"Enter");
    
    if (_playerFactory.castProvider.isConnected) {
        return;
    }
    
    NSArray *backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
    
    if ([backgroundModes containsObject:@"audio"]) {
        [self.playerFactory enableTracks:YES];
    }

    if (_activatedFromBackground) {
        [self.playerFactory backToForeground];
        _activatedFromBackground = NO;
    }
    
    KPLogTrace(@"Exit");
}

- (void)didPinchInOut:(UIPinchGestureRecognizer *)gestureRecognizer {
    
}

- (void)reload:(UIButton *)sender {
    [self.controlsView loadRequest:[NSURLRequest requestWithURL:[self.currentConfiguration appendConfiguration:videoURL]]];
}

- (UIWindow *)topWindow {
    if ([UIApplication sharedApplication].keyWindow) {
        return [UIApplication sharedApplication].keyWindow;
    }
    return [UIApplication sharedApplication].windows.firstObject;
}

- (void)changeMedia:(NSString *)mediaID {
    if (mediaID) {
        NSDictionary *mediaDict = @{@"entryId": mediaID};
        [self sendNotification:@"changeMedia" withParams:mediaDict.toJson];
    }
}

- (void)changeConfiguration:(KPPlayerConfig *)config {
    if (config) {
        _currentConfiguration = config;
        _currentConfiguration.supportedMediaFormats = [KPAssetBuilder supportedMediaFormats];
        
        [self.playerFactory prepareForChangeConfiguration];
        [self.controlsView loadRequest:[NSURLRequest requestWithURL:config.videoURL]];
        isJsCallbackReady = NO;
        [self registerReadyEvent:^{
            for (NSString *event in self.kPlayerEventsDict.allKeys) {
                [self.controlsView addEventListener:event];
            }
        }];
    }
}

- (void) prefetchPlayerResourcesWithConfig:(KPPlayerConfig *)config {
    
    __block UIViewController *ownerViewController = [[UIViewController alloc] init];
    [config addConfigKey:@"EmbedPlayer.PreloadNativeComponent" withValue:@"true"];
    [config addConfigKey:@"autoPlay" withValue:@"false"];
    
    KPViewController *playerViewController = [[KPViewController alloc] initWithConfiguration: config];
    
    [ownerViewController addChildViewController: playerViewController];
    [ownerViewController.view addSubview: playerViewController.view];
    
    [playerViewController registerReadyEvent:^{
        
        KPLogTrace(@"Player ready after prefetch - will now destroy player");
        [playerViewController removePlayer];
        ownerViewController = nil;
    }];
}

#pragma mark - Player Methods

-(void)initPlayerParams {
    KPLogTrace(@"Enter");
    
    isFullScreen = NO;
    isPlaying = NO;
    isResumePlayer = NO;
    _isFullScreenToggled = NO;
    isActionSheetPresented = NO;
    KPLogTrace(@"Exit");
}

#pragma mark -
#pragma Kaltura Player External API - KDP API
- (void)registerReadyEvent:(void (^)())handler {
    KPLogTrace(@"Enter");
    
    if (isJsCallbackReady) {
        handler();
    } else {
        if (!callBackReadyRegistrations) {
            callBackReadyRegistrations = [NSMutableArray new];
        }
        if (handler) {
            [callBackReadyRegistrations addObject:handler];
        }
    }
    KPLogTrace(@"Exit");
}

- (void(^)(void(^)()))registerReadyEvent {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    return ^(void(^readyCallback)()){
        [weakSelf registerReadyEvent:readyCallback];
        KPLogTrace(@"Exit");
    };
}



- (void)addKPlayerEventListener:(NSString *)event
                        eventID:(NSString *)eventID
                        handler:(void (^)(NSString *, NSString *))handler {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    [self registerReadyEvent:^{
        NSMutableArray *listenerArr = self.kPlayerEventsDict[event];
        if (!listenerArr) {
            listenerArr = [NSMutableArray new];
        }
        [listenerArr addObject:@{eventID: handler}];
        self.kPlayerEventsDict[event] = listenerArr;
        if (listenerArr.count == 1 && !event.isToggleFullScreen) {
            [weakSelf.controlsView addEventListener:event];
        }
        KPLogTrace(@"Exit");
    }];
}

- (void(^)(NSString *, NSString *, void(^)(NSString *, NSString *)))addEventListener {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    return ^(NSString *event, NSString *eventID, void(^completion)(NSString *, NSString *)){
        [weakSelf addKPlayerEventListener:event eventID:eventID handler:completion];
        KPLogTrace(@"Exit");
    };
}

- (void)removeKPlayerEventListener:(NSString *)event
                           eventID:(NSString *)eventID {
    KPLogTrace(@"Enter");
    NSMutableArray *listenersArr = self.kPlayerEventsDict[event];
    if ( listenersArr == nil || [listenersArr count] == 0 ) {
        KPLogInfo(@"No such event to remove");
        return;
    }
    NSArray *temp = listenersArr.copy;
    for (NSDictionary *dict in temp) {
        if ([dict.allKeys.lastObject isEqualToString:eventID]) {
            [listenersArr removeObject:dict];
        }
    }
    if ( !listenersArr.count ) {
        listenersArr = nil;
        if (!event.isToggleFullScreen) {
            [self.controlsView removeEventListener:event];
        }
    }
    KPLogTrace(@"Exit");
}

- (void(^)(NSString *, NSString *))removeEventListener {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    return ^(NSString *event, NSString *eventID) {
        [weakSelf removeKPlayerEventListener:event eventID:eventID];
        KPLogTrace(@"Exit");
    };
}

- (void)asyncEvaluate:(NSString *)expression
         expressionID:(NSString *)expressionID
              handler:(void(^)(NSString *))handler {
    KPLogTrace(@"Enter");
    self.kPlayerEvaluatedDict[expressionID] = handler;
    [self.controlsView evaluate:expression evaluateID:expressionID];
    KPLogTrace(@"Exit");
}

- (void(^)(NSString *, NSString *, void(^)(NSString *)))asyncEvaluate {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    return ^(NSString *expression, NSString *expressionID, void(^handler)(NSString *value)) {
        [weakSelf asyncEvaluate:expression expressionID:expressionID handler:handler];
        KPLogTrace(@"Exit");
    };
}

- (void)notifyKPlayerEvaluated: (NSArray *)arr {
    KPLogTrace(@"Enter");
    if (arr.count == 2) {
        ((void(^)(NSString *))self.kPlayerEvaluatedDict[arr[0]])(arr[1]);
    } else if (arr.count < 2) {
        KPLogDebug(@"Missing Evaluation Params");
    }
    KPLogTrace(@"Exit");
}

- (void)sendNotification:(NSString *)notificationName withParams:(NSString *)params {
    KPLogTrace(@"Enter");
    if ( !notificationName || [ notificationName isKindOfClass: [NSNull class] ] ) {
        notificationName = @"null";
    }
    [self.controlsView sendNotification:notificationName withParams:params];
    KPLogTrace(@"Exit");
}

- (void(^)(NSString *, NSString *))sendNotification {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    return ^(NSString *notification, NSString *params){
        [weakSelf sendNotification:notification withParams:params];
        KPLogTrace(@"Exit");
    };
}

- (void)setKDPAttribute:(NSString *)pluginName
           propertyName:(NSString *)propertyName
                  value:(NSString *)value {
    KPLogTrace(@"Enter");
    [self.controlsView setKDPAttribute:pluginName propertyName:propertyName value:value];
    KPLogTrace(@"Exit");
}

- (void(^)(NSString *, NSString *, NSString *))setKDPAttribute {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    return ^(NSString *pluginName, NSString *propertyName, NSString *value) {
        [weakSelf setKDPAttribute:pluginName propertyName:propertyName value:value];
        KPLogTrace(@"Exit");
    };
}

- (void)triggerEvent:(NSString *)event withValue:(NSString *)value {
    KPLogTrace(@"Enter");
    [self.controlsView triggerEvent:event withValue:value];
    KPLogTrace(@"Exit");
}

- (void(^)(NSString *, NSString *))triggerEvent {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    return ^(NSString *event, NSString *value){
        [weakSelf triggerEvent:event withValue:value];
        KPLogTrace(@"Exit");
    };
}

#pragma mark Errors triggerd by WebView Delegate
- (void)handleKPControlsError:(NSError *)error {
    if (_delegate && [_delegate respondsToSelector:@selector(kPlayer:didFailWithError:)]) {
        [_delegate kPlayer:self didFailWithError:error];
    }
}

#pragma mark HTML lib events triggerd by WebView Delegate
// "pragma clang" is attached to prevent warning from “PerformSelect may cause a leak because its selector is unknown”
- (void)handleHtml5LibCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args{
       KPLogTrace(@"Enter");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ( [args count] > 0 ) {
        functionName = [NSString stringWithFormat:@"%@:", functionName];
    }
    SEL selector = NSSelectorFromString(functionName);
    if ([self respondsToSelector:selector]) {
        [self performSelector:selector withObject:args];
    } else if ([_playerFactory respondsToSelector:selector]) {
        [_playerFactory performSelector:selector withObject:args];
    }else if ([_playerFactory.player respondsToSelector:selector]) {
        [_playerFactory.player performSelector:selector withObject:args];
    }
    
#pragma clang diagnostic pop
    
    KPLogTrace(@"Exit");
}

- (void)setAttribute: (NSArray*)args{
    KPLogTrace(@"Enter");
    NSString *attributeName = [args objectAtIndex:0];
    NSString *attributeVal = args[1];
    
    switch ( attributeName.attributeEnumFromString ) {
        case src: {
            NSString *overrideURL = [_customSourceURLProvider urlForEntryId:_currentConfiguration.entryId currentURL:attributeVal];
            if (overrideURL) {
                attributeVal = overrideURL;
            }
            
            if (self.currentConfiguration.startFrom > 0.0) {
                [_playerFactory setCurrentPlayBackTime:self.currentConfiguration.startFrom];
            }
            _playerFactory.src = attributeVal;
        }
            break;
        case currentTime:
            _playerFactory.currentPlayBackTime = [attributeVal doubleValue];
            break;
        case visible:
            [self visible: attributeVal];
            break;
        case audioTrackSelected:
            [_playerFactory selectAudioTrack:(int)[attributeVal integerValue]];
            break;
        case textTrackSelected:
            [_playerFactory selectTextTrack:attributeVal];
            break;
        case playerError:
            if ([_delegate respondsToSelector:@selector(kPlayer:didFailWithError:)]) {
                NSDictionary *dict = @{NSLocalizedDescriptionKey:attributeVal,
                                       NSLocalizedFailureReasonErrorKey:attributeVal};
                NSError *err = [NSError errorWithDomain:KPErrorDomain code:KPErrorMsg userInfo:dict];
                [_delegate kPlayer:self didFailWithError:err];
            }
            break;
        case licenseUri:
            _playerFactory.licenseUri = attributeVal;
            break;
        case fpsCertificate:
            [_playerFactory setAssetParam:attributeName toValue:attributeVal];
             break;
        case nativeAction:
            nativeActionParams = [NSJSONSerialization JSONObjectWithData:[attributeVal dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:nil];
            break;
        case language:
            _playerFactory.locale = attributeVal;
            break;
        case chromecastAppId:
            if (_playerFactory.castProvider.isConnected) {
                [self.controlsView triggerEvent:@"chromecastDeviceConnected" withValue:[NSString stringWithFormat:@"%f", self.currentPlaybackTime]];
            }
            break;
        case doubleClickRequestAds: {
            if ([_currentConfiguration
                 configValueForKey:@"EmbedPlayer.UseExternalAdPlayer"]) {
                return;
            }
            __weak KPViewController *weakSelf = self;
            [self.controlsView fetchvideoHolderHeight:^(CGFloat height) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.playerFactory.adPlayerHeight = height;
                    weakSelf.playerFactory.adTagURL = attributeVal;
                });
            }];
        }
            break;
        case captions:
//            _playerController changeSubtitleLanguage
            break;
        default:
            KPLogDebug(@"Unhandled attribute: %@=%@", attributeName, attributeVal);
            break;
    }
    KPLogTrace(@"Exit");
}

- (void)sendCCRecieverMessage:(NSDictionary *)message {
    [_playerFactory sendCastRecieverTextMessage:message.toJson];
}

-(void)visible:(NSString *)boolVal{
    KPLogTrace(@"Enter");
    self.triggerEvent(@"visible", [NSString stringWithFormat:@"%@", boolVal]);
    KPLogTrace(@"Exit");
}

- (void)toggleFullscreen {
    KPLogTrace(@"Enter");
    _isFullScreenToggled = !_isFullScreenToggled;
    if (!_fullScreenToggeled) {
        
        if (_isFullScreenToggled) {
            self.view.frame = screenBounds();
            [self.topWindow addSubview:self.view];
            [self.topWindow makeKeyAndVisible];
            [self.topWindow.rootViewController.view addSubview:self.view];
        } else {
            self.view.frame = self.superView.bounds;
            [self.superView addSubview:self.view];
        }
    } else {
        _fullScreenToggeled(_isFullScreenToggled);
    }
    
    [self.controlsView updateLayout];
    
    if ([_delegate respondsToSelector:@selector(kPlayer:playerFullScreenToggled:)]) {
        [_delegate kPlayer:self playerFullScreenToggled:_isFullScreenToggled];
    }
    
    KPLogTrace(@"Exit");
}

- (void)notifyKPlayerEvent: (NSArray *)arr {
    KPLogTrace(@"Enter");
    NSString *eventName = arr.firstObject;
    NSString *params = arr.lastObject;
    NSArray *listenersArr = self.kPlayerEventsDict[ eventName ];
    
    if ( listenersArr != nil ) {
        for (NSDictionary *eDict in listenersArr) {
            ((void(^)(NSString *, NSString *))eDict.allValues.lastObject)(eventName, params);
        }
    }
    KPLogTrace(@"Exit");
}

- (void)notifyJsReady {
    
    KPLogTrace(@"Enter");
    isJsCallbackReady = YES;
    NSArray *registrations = callBackReadyRegistrations.copy;
    for (void(^handler)() in registrations) {
        handler();
        [callBackReadyRegistrations removeObject:handler];
    }
    callBackReadyRegistrations = nil;
    _kdpAPIState = KDPAPIStateReady;
    KPLogTrace(@"Exit");
}

- (void)doNativeAction {
    KPLogTrace(@"Enter");
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL nativeAction = NSSelectorFromString(nativeActionParams.actionType);
    [self performSelector:nativeAction withObject:nil];
#pragma clang diagnostic pop
    KPLogTrace(@"Exit");
}

#pragma mark Native Action methods
- (void)share {
    KPLogTrace(@"Enter");
    if (_shareHandler) {
        _shareHandler(nativeActionParams);
    } else {
        self.shareManager = [KPShareManager new];
        self.shareManager.datasource = nativeActionParams;
        __weak KPViewController *weakSelf = self;
        UIViewController *shareController = [self.shareManager shareWithCompletion:^(KPShareResults result,
                                                                                     KPShareError *shareError) {
            if (shareError.error) {
                KPLogError(@"%@", shareError.error.description);
            }
            weakSelf.shareManager = nil;
        }];
        [self presentViewController:shareController animated:YES completion:nil];
    }
    KPLogTrace(@"Exit");
}

- (void)openURL {
    KPLogTrace(@"Enter");
    KPBrowserViewController *browser = [KPBrowserViewController currentBrowser];
    browser.url = nativeActionParams.openURL;
    [self presentViewController:browser animated:YES completion:nil];
    KPLogTrace(@"Exit");
}

#pragma mark KPlayerDelegate
- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event value:(NSString *)value {
    __block KPMediaPlaybackState playbackState = KPMediaPlaybackStateUnknown;
    
    if ([event isEqualToString:@"seeked"]) {
        if (_seekedEventHandler) {
            KPLogDebug(@"call seekedEventHandler");
            _seekedEventHandler();
            _seekedEventHandler = nil;
        }
    }
    __weak KPViewController *weakSelf = self;
    void(^kPlayerStateBlock)() = @{
                                      CanPlayKey:
                                          ^{
                                              [[NSNotificationCenter defaultCenter] postNotificationName:KPMediaPlaybackStateDidChangeNotification
                                                                                                  object:weakSelf
                                                                                                userInfo:@{KMediaPlaybackStateKey:@(KPMediaLoadStatePlayable)}];
                                              
                                              if ([_delegate respondsToSelector:@selector(kPlayer:playerLoadStateDidChange:)]) {
                                                  [_delegate kPlayer:self playerLoadStateDidChange:KPMediaLoadStatePlayable];
                                              }
                                          },
                                      PlayKey:
                                          ^{
                                              playbackState = KPMediaPlaybackStatePlaying;
                                              [[NSNotificationCenter defaultCenter] postNotificationName:KPMediaPlaybackStateDidChangeNotification
                                                                                                  object:weakSelf
                                                                                                userInfo:@{KMediaPlaybackStateKey:@(playbackState)}];
                                          },
                                      PauseKey:
                                          ^{
                                              playbackState = KPMediaPlaybackStatePaused;
                                              [[NSNotificationCenter defaultCenter] postNotificationName:KPMediaPlaybackStateDidChangeNotification
                                                                                                  object:weakSelf
                                                                                                userInfo:@{KMediaPlaybackStateKey:@(playbackState)}];
                                          },
                                      EndedKey:
                                          ^{
                                              playbackState = KPMediaPlaybackStateEnded;
                                              [[NSNotificationCenter defaultCenter] postNotificationName:KPMediaPlaybackStateDidChangeNotification
                                                                                                  object:weakSelf
                                                                                                userInfo:@{KMediaPlaybackStateKey:@(playbackState)}];
                                          },
                                      TimeUpdateKey:
                                          ^{
                                              if([_delegate respondsToSelector:@selector(updateCurrentPlaybackTime:)]) {
                                                  [_delegate updateCurrentPlaybackTime:_playerFactory.currentPlayBackTime];
                                              }
                                          }
                                      }[event];

    if (kPlayerStateBlock != nil) {
        kPlayerStateBlock();
    }
    
    if (playbackState != KPMediaPlaybackStateUnknown) {
        [self playerPlaybackStateDidChange:playbackState];
        [self.playerController setPlaybackState:playbackState];
    }
    
    [self.controlsView triggerEvent:event withValue:value];
}

- (void)playerPlaybackStateDidChange:(KPMediaPlaybackState)playbackState {
    if ([_delegate respondsToSelector:@selector(kPlayer:playerPlaybackStateDidChange:)]) {
        [_delegate kPlayer:self playerPlaybackStateDidChange:playbackState];
    }
}

- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event JSON:(NSString *)jsonString {
    [self.controlsView triggerEvent:event withJSON:jsonString];
}

- (void)contentCompleted:(id<KPlayer>)currentPlayer {
    [self player:currentPlayer eventName:EndedKey value:nil];
}

- (void)allAdsCompleted {
    [self.controlsView triggerEvent:AllAdsCompletedKey withJSON:nil];
}

- (void)triggerKPlayerNotification: (NSNotification *)note{
    KPLogTrace(@"Enter");
    isPlaying = note.name.isPlay || (!note.name.isPause && !note.name.isStop);
    [self.controlsView triggerEvent:note.name withValue:note.userInfo[note.name]];
    KPLogDebug(@"%@\n%@", note.name, note.userInfo[note.name]);
    KPLogTrace(@"Exit");
}

#pragma mark -
#pragma mark Rotation methods
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (BOOL)shouldAutorotate{
    return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.currentConfiguration.supportedInterfaceOrientations;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (!_isModifiedFrame || _isFullScreenToggled) {
        [self.view.layer.sublayers.firstObject setFrame:screenBounds()];
        ((UIView *)self.controlsView).frame = screenBounds();
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc {
    KPLogInfo(@"Dealloc");
}

#pragma mark KPControllerDelegate

- (void)sendKPNotification:(NSString *)kpNotificationName withParams:(NSString *)kpParams {
    KPLogTrace(@"Enter");
    
    if (kpNotificationName) {
        [self sendNotification:kpNotificationName withParams:kpParams];
    }
    
    KPLogTrace(@"Exit");
}

- (void)sendKPNotification:(NSString *)kpNotificationName
                    params:(NSString *)kpParams completionHandler:(void(^)())handler {
    KPLogTrace(@"Enter");
    
    if ([kpNotificationName isEqualToString:@"doSeek"]) {
        _seekedEventHandler = [handler copy];
    }
    
    if (kpNotificationName) {
        [self sendNotification:kpNotificationName withParams:kpParams];
    }
    
    KPLogTrace(@"Exit");
}

- (id<KPlayer>)kPlayer {
    KPLogTrace(@"Enter");
    
    if (_playerFactory.player && [_playerFactory.player isKindOfClass:[AVPlayer class]]) {
        KPLogTrace(@"Exit");
        return _playerFactory.player;
    }

    KPLogTrace(@"Exit::nil");
    return nil;
}

@end


