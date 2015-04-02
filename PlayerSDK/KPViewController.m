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
#import "KPlayerController.h"

#include <sys/types.h>
#include <sys/sysctl.h>


typedef NS_ENUM(NSInteger, KPActionType) {
    KPActionTypeShare,
    KPActionTypeOpenHomePage,
    KPActionTypeSkip
};

@interface KPViewController() <KPlayerControllerDelegate, PlayerControlsWebViewDelegate>{
    // Player Params
    BOOL isFullScreen, isPlaying, isResumePlayer;
    NSDictionary *appConfigDict;
    BOOL isCloseFullScreenByTap;
    BOOL isJsCallbackReady;
    NSDictionary *nativeActionParams;
    NSMutableArray *callBackReadyRegistrations;
    NSURL *videoURL;
}

@property (nonatomic, strong) KPControlsWebView* webView;
@property (nonatomic, copy) NSMutableDictionary *kPlayerEventsDict;
@property (nonatomic, copy) NSMutableDictionary *kPlayerEvaluatedDict;
@property (nonatomic, strong) KPShareManager *shareManager;
@property (nonatomic, strong) KPlayerController *playerController;
@property (nonatomic) BOOL isModifiedFrame;
@property (nonatomic) BOOL isFullScreenToggled;
@property (nonatomic, strong) UIView *superView;
@end

@implementation KPViewController 
@synthesize webView;

+ (void)setLogLevel:(KPLogLevel)logLevel {
    @synchronized(self) {
        KPLogManager.KPLogLevel = logLevel;
    }
}


#pragma mark Initialize methods
- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        videoURL = [NSURL URLWithString:url.absoluteString.appendHover];
        return self;
    }
    return nil;
}

- (instancetype)initWithConfiguration:(KPPlayerConfig *)configuration {
    self = [self initWithURL:configuration.videoURL];
    if (self) {
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
    [self.webView removeFromSuperview];
    self.webView.delegate = nil;
    self.webView = nil;
    [self.playerController removePlayer];
    self.playerController = nil;
    [callBackReadyRegistrations removeAllObjects];
    callBackReadyRegistrations = nil;
    appConfigDict = nil;
    nativeActionParams = nil;
    videoURL = nil;
    [self.kPlayerEvaluatedDict removeAllObjects];
    self.kPlayerEvaluatedDict = nil;
    [self.kPlayerEventsDict removeAllObjects];
    self.kPlayerEventsDict = nil;
    [self.view removeObserver:self forKeyPath:@"frame" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    self.superView = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (keyPath.isFrameKeypath) {
        if ([object isEqual:self.view]) {
            [self.view.layer.sublayers.firstObject setFrame:(CGRect){CGPointZero, self.view.frame.size}];
            self.webView.frame = (CGRect){CGPointZero, self.view.frame.size};
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

- (NSString *) platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}


#pragma mark -
#pragma mark View flow methods
- (void)viewDidLoad {
    KPLogTrace(@"Enter");
    appConfigDict = extractDictionary(AppConfigurationFileName, @"plist");
    setUserAgent();
    [self initPlayerParams];
    
    // Pinch Gesture Recognizer - Player Enter/ Exit FullScreen mode
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(didPinchInOut:)];
    [self.view addGestureRecognizer:pinch];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    [self.view addObserver:self
                forKeyPath:@"frame"
                   options:NSKeyValueObservingOptionNew
                   context:nil];

    // Initialize players controller
    if (!_playerController) {
        _playerController = [[KPlayerController alloc] initWithPlayerClassName:PlayerClassName];
        [_playerController addPlayerToController:self];
        _playerController.delegate = self;
    }
    // Initialize HTML layer (controls)
    if (!self.webView) {
        self.webView = [[KPControlsWebView alloc] initWithFrame:(CGRect){CGPointZero, self.view.frame.size}];
        self.webView.playerControlsWebViewDelegate = self;
        [self.webView loadRequest:[NSURLRequest requestWithURL:videoURL]];
        [self.view addSubview:self.webView];
    }
    
    // Handle full screen events
    __weak KPViewController *weakSelf = self;
    [self registerReadyEvent:^{
        if (!weakSelf.isModifiedFrame) {
            weakSelf.setKDPAttribute(@"fullScreenBtn", @"visible", @"false");
        } else {
            weakSelf.addEventListener(KPlayerEventToggleFullScreen, @"defaultFS", ^(NSString *eventId) {
                weakSelf.isFullScreenToggled = !self.isFullScreenToggled;
                
                if (weakSelf.isFullScreenToggled) {
                    weakSelf.view.frame = [UIScreen mainScreen].bounds;
                    [weakSelf.topWindow addSubview:weakSelf.view];
                } else {
                    weakSelf.view.frame = weakSelf.superView.bounds;
                    [weakSelf.superView addSubview:weakSelf.view];
                }
            });
        }
    }];
    [super viewDidLoad];
    KPLogTrace(@"Exit");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_superView) {
        _superView = self.view.superview;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    KPLogTrace(@"Enter");
    isResumePlayer = YES;
    [super viewDidDisappear:animated];
    KPLogTrace(@"Exit");
}



- (void)handleEnteredBackground: (NSNotification *)not {
    KPLogTrace(@"Enter");
    self.sendNotification(nil, @"doPause");
    KPLogTrace(@"Exit");
}


- (UIWindow *)topWindow {
    if ([UIApplication sharedApplication].keyWindow) {
        return [UIApplication sharedApplication].keyWindow;
    }
    return [UIApplication sharedApplication].windows.firstObject;
}

- (void)changeMedia:(NSString *)mediaID {
    NSString *name = [NSString stringWithFormat:@"'{\"entryId\":\"%@\"}'", mediaID];
    [self sendNotification:@"changeMedia" forName:name];
}

#pragma mark - Player Methods

-(void)initPlayerParams {
    KPLogTrace(@"Enter");
    isFullScreen = NO;
    isPlaying = NO;
    isResumePlayer = NO;
    _isFullScreenToggled = NO;
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



- (void)addEventListener:(NSString *)event
                 eventID:(NSString *)eventID
                 handler:(void (^)(NSString *))handler {
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
            [weakSelf.webView addEventListener:event];
        }
        KPLogTrace(@"Exit");
    }];
}

- (void(^)(NSString *, NSString *, void(^)(NSString *)))addEventListener {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    return ^(NSString *event, NSString *eventID, void(^completion)()){
        [weakSelf addEventListener:event eventID:eventID handler:completion];
        KPLogTrace(@"Exit");
    };
}

- (void)removeEventListener:(NSString *)event
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
            [self.webView removeEventListener:event];
        }
    }
    KPLogTrace(@"Exit");
}

- (void(^)(NSString *, NSString *))removeEventListener {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    return ^(NSString *event, NSString *eventID) {
        [weakSelf removeEventListener:event eventID:eventID];
        KPLogTrace(@"Exit");
    };
}

- (void)asyncEvaluate:(NSString *)expression
         expressionID:(NSString *)expressionID
              handler:(void(^)(NSString *))handler {
    KPLogTrace(@"Enter");
    self.kPlayerEvaluatedDict[expressionID] = handler;
    [self.webView evaluate:expression evaluateID:expressionID];
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

- (void)sendNotification:(NSString *)notification forName:(NSString *)notificationName {
    KPLogTrace(@"Enter");
    if ( !notification || [ notification isKindOfClass: [NSNull class] ] ) {
        notification = @"null";
    }
    [self.webView sendNotification:notification withName:notificationName];
    KPLogTrace(@"Exit");
}

- (void(^)(NSString *, NSString *))sendNotification {
    KPLogTrace(@"Enter");
    __weak KPViewController *weakSelf = self;
    return ^(NSString *notification, NSString *notificationName){
        [weakSelf sendNotification:notification forName:notificationName];
        KPLogTrace(@"Exit");
    };
}

- (void)setKDPAttribute:(NSString *)pluginName
           propertyName:(NSString *)propertyName
                  value:(NSString *)value {
    KPLogTrace(@"Enter");
    [self.webView setKDPAttribute:pluginName propertyName:propertyName value:value];
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
    [self.webView triggerEvent:event withValue:value];
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
    } else if ([_playerController.player respondsToSelector:selector]) {
        [_playerController.player performSelector:selector withObject:args];
    }
    
#pragma clang diagnostic pop
    
    KPLogTrace(@"Exit");
}


- (void)setAttribute: (NSArray*)args{
    KPLogTrace(@"Enter");
    NSString *attributeName = [args objectAtIndex:0];
    NSString *attributeVal = args[1];
    
    switch ( attributeName.attributeEnumFromString ) {
        case src:
            _playerController.src = attributeVal;
            break;
        case currentTime:
            _playerController.currentPlayBackTime = [attributeVal doubleValue];
            break;
        case visible:
            [self visible: attributeVal];
            break;
#if !(TARGET_IPHONE_SIMULATOR)
        case wvServerKey:
            [_playerController switchPlayer:WideVinePlayerClass key:attributeVal];
            break;
#endif
        case nativeAction:
            nativeActionParams = [NSJSONSerialization JSONObjectWithData:[attributeVal dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:nil];
            break;
        case language:
            _playerController.locale = attributeVal;
            break;
        case doubleClickRequestAds:
            _playerController.adPlayerHeight = self.webView.videoHolderHeight;
            _playerController.adTagURL = attributeVal;
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
    if (self.kPlayerEventsDict[KPlayerEventToggleFullScreen]) {
        NSArray *listenersArr = self.kPlayerEventsDict[ KPlayerEventToggleFullScreen ];
        if ( listenersArr != nil ) {
            for (NSDictionary *eDict in listenersArr) {
                ((void(^)())eDict.allValues.lastObject)(eDict.allKeys.firstObject);
            }
        }
    } else {
        isCloseFullScreenByTap = YES;
        _isFullScreenToggled = YES;
    }
    KPLogTrace(@"Exit");
}

- (void)notifyKPlayerEvent: (NSArray *)arr {
    KPLogTrace(@"Enter");
    NSString *eventName = arr[0];
    NSArray *listenersArr = self.kPlayerEventsDict[ eventName ];
    
    if ( listenersArr != nil ) {
        for (NSDictionary *eDict in listenersArr) {
            ((void(^)(NSString *))eDict.allValues.lastObject)(eventName);
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
    [self.webView triggerEvent:event withValue:value];
}

- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event JSON:(NSString *)jsonString {
    [self.webView triggerEvent:event withJSON:jsonString];
}

- (void)contentCompleted:(id<KPlayer>)currentPlayer {
    [self player:currentPlayer eventName:EndedKey value:nil];
}

- (void)allAdsCompleted {
    [self.webView triggerEvent:PostrollEndedKey withJSON:nil];
}


- (void)triggerKPlayerNotification: (NSNotification *)note{
    KPLogTrace(@"Enter");
    isPlaying = note.name.isPlay || (!note.name.isPause && !note.name.isStop);
    [self.webView triggerEvent:note.name withValue:note.userInfo[note.name]];
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

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
    
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (!_isModifiedFrame || _isFullScreenToggled) {
        self.view.frame = [UIScreen mainScreen].bounds;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc {
    KPLogInfo(@"Dealloc");
}
@end


