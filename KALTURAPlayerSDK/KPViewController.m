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
#import "KCCPlayer.h"
#import "KPController_Private.h"
#import "KPURLProtocol.h"
#import "KCacheManager.h"
#import "NSBundle+Kaltura.h"
#import "NSDictionary+Utilities.h"

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
                                ChromecastDeviceControllerDelegate, KPControllerDelegate> {
    // Player Params
    BOOL isFullScreen, isPlaying, isResumePlayer;
    NSDictionary *appConfigDict;
    BOOL isCloseFullScreenByTap;
    BOOL isJsCallbackReady;
    NSDictionary *nativeActionParams;
    NSMutableArray *callBackReadyRegistrations;
    NSURL *videoURL;
    void(^_shareHandler)(NSDictionary *);
                                    
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

#pragma mark - chromecast
@property  id<KPGCDevice>selectedDevice;

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
        videoURL = [NSURL URLWithString:url.absoluteString];
        
        return self;
    }
    return nil;
}

- (instancetype)initWithConfiguration:(KPPlayerConfig *)configuration {
    self = [self initWithURL:configuration.videoURL];
    if (self) {
        _configuration = configuration;
        // If the developer set the cache size, the cache system is triggered.
        if (_configuration.cacheSize > 0) {
            [NSURLProtocol registerClass:[KPURLProtocol class]];
            CacheManager.baseURL = configuration.server;
            CacheManager.cacheSize = _configuration.cacheSize;
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
        NSLog(@"frame not observed");
    }
    
    _delegate = nil;
    _playerController = nil;
    _configuration = nil;
    _kdpAPIState = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    _superView = nil;
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

- (KPPlayerConfig *)configuration {
    
    if (!_configuration) {
        _configuration = [KPPlayerConfig new];
    }
    
    return _configuration;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    // Assign ourselves as delegate ONLY in viewWillAppear of a view controller.
    [ChromecastDeviceController sharedInstance].delegate = self;
    NSLog(@"%@", [NSValue valueWithCGRect:((UIView *)self.controlsView).frame]);
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
        [self.controlsView loadRequest:[NSURLRequest requestWithURL:[self.configuration appendConfiguration:videoURL]]];
        [self.view addSubview:(UIView *)self.controlsView];
        _kdpAPIState = KDPAPIStateUnknown;
    }
    
    // Handle full screen events
    __weak KPViewController *weakSelf = self;
    [self registerReadyEvent:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:KPMediaPlaybackStateDidChangeNotification object:weakSelf userInfo:@{KMediaPlaybackStateKey: @(KPMediaPlaybackStateLoaded)}];
        [weakSelf.playerController setPlaybackState:KPMediaPlaybackStateLoaded];
        if (!weakSelf.isModifiedFrame) {
            weakSelf.setKDPAttribute(@"fullScreenBtn", @"visible", @"false");
        } else {
            weakSelf.addEventListener(KPlayerEventToggleFullScreen, @"defaultFS", ^(NSString *eventId, NSString *params) {
                weakSelf.isFullScreenToggled = !self.isFullScreenToggled;
                weakSelf.controlsView.shouldUpdateLayout = YES;
                if (weakSelf.isFullScreenToggled) {
                    weakSelf.view.frame = screenBounds();
                    [weakSelf.topWindow makeKeyAndVisible];
                    [weakSelf.topWindow.rootViewController.view addSubview:weakSelf.view];
                } else {
                    weakSelf.view.frame = weakSelf.superView.bounds;
                    [weakSelf.superView addSubview:weakSelf.view];
                }
            });
        }
    }];
    
    self.castDeviceController = [ChromecastDeviceController sharedInstance];
    if (self.castDeviceController) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleCastScanStatusUpdated)
                                                     name: @"castScanStatusUpdated"
                                                   object: nil];
        [self.castDeviceController clearPreviousSession];
        // Assign ourselves as the delegate.
        self.castDeviceController.delegate = self;
        // Turn on the Cast logging for debug purposes.
        [self.castDeviceController enableLogging];
        // Set the receiver application ID to initialise scanning.
        [self.castDeviceController setApplicationID:@"DB6462E9"];
    }
    
    [super viewDidLoad];
    KPLogTrace(@"Exit");
}

- (void)handleCastScanStatusUpdated {

}

#pragma mark - GCKDeviceScannerListener
- (void)didDiscoverDeviceOnNetwork {
    KPLogChromeCast(@"");
    __weak KPViewController *weakSelf = self;
    [self registerReadyEvent:^{
        [weakSelf setKDPAttribute:@"chromecast" propertyName:@"visible" value:@"true"];
    }];
}

- (void)chooseDevice {
    UIActionSheet *sheet;
    //Choose device
    if (!self.selectedDevice) {
        //Choose device
       sheet =
        [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Connect to Device", nil)
                                    delegate:self
                           cancelButtonTitle:nil
                      destructiveButtonTitle:nil
                           otherButtonTitles:nil];
        
        for (id<KPGCDevice> device in self.castDeviceController.deviceScanner.devices) {
            [sheet addButtonWithTitle:device.friendlyName];
        }
        
        [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
//        sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
        
        //show device selection
//    }
    } else {
        // Gather stats from device.
//        [self updateStatsFromDevice];
        
        NSString *friendlyName = [NSString stringWithFormat:NSLocalizedString(@"Casting to %@", nil),
                            self.selectedDevice.friendlyName];
        /**
         *  @todo replace Title with GoogleCast constant
         */
        NSString *mediaTitle = [self.castDeviceController.mediaInformation.metadata stringForKey:@"Title"];
        
        sheet = [[UIActionSheet alloc] init];
        sheet.title = friendlyName;
        sheet.delegate = self;
        if (mediaTitle != nil) {
            [sheet addButtonWithTitle:mediaTitle];
        }
        
        //Offer disconnect option
        [sheet addButtonWithTitle:@"Disconnect"];
        [sheet addButtonWithTitle:@"Cancel"];
        sheet.destructiveButtonIndex = (mediaTitle != nil ? 1 : 0);
        sheet.cancelButtonIndex = (mediaTitle != nil ? 2 : 1);
    }
    
    [sheet showInView:[[[[UIApplication sharedApplication] keyWindow] subviews] lastObject]];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    isActionSheetPresented = YES;
}

-(void)showChromecastDeviceList {
    NSLog(@"showChromecastDeviceList Enter");
    
    if (!isActionSheetPresented) {
        [self chooseDevice];
    }
    
    NSLog(@"showChromecastDeviceList Exit");
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    isActionSheetPresented = NO;
    
    if (self.selectedDevice == nil) {
        if (buttonIndex < self.castDeviceController.deviceScanner.devices.count) {
            self.selectedDevice = self.castDeviceController.deviceScanner.devices[buttonIndex];
            [_playerFactory changePlayer:[_playerFactory createPlayerFromClassName:ChromeCastPlayerClassName]];
            [((KCCPlayer *)_playerFactory.player).chromecastDeviceController connectToDevice:self.selectedDevice];
        }
    } else {
        if (buttonIndex == 0) {  //Disconnect button
            NSLog(@"Disconnecting device:%@", self.selectedDevice.friendlyName);
            // New way of doing things: We're not going to stop the applicaton. We're just going
            // to leave it.
//            [self.castDeviceController.deviceManager leaveApplication];
            // If you want to force application to stop, uncomment below
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//            [defaults setObject:sessionID forKey:@"lastSessionID"];
            [self.castDeviceController.deviceManager stopApplicationWithSessionID: [defaults objectForKey:@"lastSessionID"]];
            
            [self.castDeviceController.deviceManager disconnect];
            [self deviceDisconnect];
        }
//        else if (buttonIndex == 0) {
//            // Join the existing session.
//            
//        }
    }
}

- (void)deviceDisconnect {
    self.selectedDevice = nil;
    self.castDeviceController.deviceManager = nil;
//    [_playerFactory switchPlayer:PlayerClassName key:nil];
    [_playerFactory changePlayer:[_playerFactory createPlayerFromClassName:PlayerClassName]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_superView) {
        _superView = self.view.superview;
    }
    if (isIOS(7) && _configuration.supportedInterfaceOrientations != UIInterfaceOrientationMaskAll) {
        [self.view.layer.sublayers.firstObject setFrame:screenBounds()];
        ((UIView *)self.controlsView).frame = screenBounds();
    }
    [self performSelector:@selector(updateControlsView) withObject:nil afterDelay:1];
//    UIButton *reloadButton = [[UIButton alloc] initWithFrame:(CGRect){20, 60, 60, 30}];
//    [reloadButton addTarget:self action:@selector(reload:) forControlEvents:UIControlEventTouchUpInside];
//    [reloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [reloadButton setTitle:@"reload" forState:UIControlStateNormal];
//    [(UIView *)self.controlsView addSubview:reloadButton];
}

- (void)updateControlsView {
//    ((UIView *)self.controlsView).frame = self.view.frame;
}

- (void)viewDidDisappear:(BOOL)animated {
    KPLogTrace(@"Enter");
    isResumePlayer = YES;
    [super viewDidDisappear:animated];
    KPLogTrace(@"Exit");
}

#pragma mark - GCKDeviceScannerListener
- (void)deviceDidComeOnline:(id<KPGCDevice>)device {
    KPLogChromeCast(@"device found!! %@", device.friendlyName);
}

- (void)deviceDidGoOffline:(id<KPGCDevice>)device {
}

- (void)applicationDidEnterBackground: (NSNotification *)not {
    KPLogTrace(@"Enter");

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
    NSArray *backgroundModes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIBackgroundModes"];
    
    if ([backgroundModes containsObject:@"audio"]) {
        [self.playerFactory enableTracks:YES];
    }
    
    KPLogTrace(@"Exit");
}

- (void)didPinchInOut:(UIPinchGestureRecognizer *)gestureRecognizer {
    
}

- (void)reload:(UIButton *)sender {
    [self.controlsView loadRequest:[NSURLRequest requestWithURL:[self.configuration appendConfiguration:videoURL]]];
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
        KPLogDebug(@"html5 call::%@ %@",functionName, args);
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
            NSString *overrideURL = [_customSourceURLProvider urlForEntryId:_configuration.entryId currentURL:attributeVal];
            if (overrideURL) {
                attributeVal = overrideURL;
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
        case nativeAction:
            nativeActionParams = [NSJSONSerialization JSONObjectWithData:[attributeVal dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:nil];
            break;
        case language:
            _playerFactory.locale = attributeVal;
            break;
        case doubleClickRequestAds: {
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
            break;
    }
    KPLogTrace(@"Exit");
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
    
    void(^kPlayerStateBlock)() = @{
                                      CanPlayKey:
                                          ^{
                                              [[NSNotificationCenter defaultCenter] postNotificationName:KPMediaPlaybackStateDidChangeNotification
                                                                                                  object:self
                                                                                                userInfo:@{KMediaPlaybackStateKey:@(KPMediaLoadStatePlayable)}];
                                              
                                              if ([_delegate respondsToSelector:@selector(kPlayer:playerLoadStateDidChange:)]) {
                                                  [_delegate kPlayer:self playerLoadStateDidChange:KPMediaLoadStatePlayable];
                                              }
                                          },
                                      PlayKey:
                                          ^{
                                              playbackState = KPMediaPlaybackStatePlaying;
                                              [[NSNotificationCenter defaultCenter] postNotificationName:KPMediaPlaybackStateDidChangeNotification
                                                                                                  object:self
                                                                                                userInfo:@{KMediaPlaybackStateKey:@(playbackState)}];
                                          },
                                      PauseKey:
                                          ^{
                                              playbackState = KPMediaPlaybackStatePaused;
                                              [[NSNotificationCenter defaultCenter] postNotificationName:KPMediaPlaybackStateDidChangeNotification
                                                                                                  object:self
                                                                                                userInfo:@{KMediaPlaybackStateKey:@(playbackState)}];
                                          },
                                      EndedKey:
                                          ^{
                                              playbackState = KPMediaPlaybackStateEnded;
                                              [[NSNotificationCenter defaultCenter] postNotificationName:KPMediaPlaybackStateDidChangeNotification
                                                                                                  object:self
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
    [self.controlsView triggerEvent:PostrollEndedKey withJSON:nil];
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
    return self.configuration.supportedInterfaceOrientations;
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

-(void)sendKPNotification:(NSString *)kpNotificationName withParams:(NSString *)kpParams {
    KPLogTrace(@"Enter");
    
    if (kpNotificationName) {
        [self sendNotification:kpNotificationName withParams:kpParams];
    }
    
    KPLogTrace(@"Exit");
}

@end


