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

static NSString *PlayerPauseNotification = @"playerPauseNotification";
static NSString *ToggleFullscreenNotification = @"toggleFullscreenNotification";

static NSString *IsFullScreenKey = @"isFullScreen";

#import "KPViewController.h"
#import "KPShareManager.h"
#import "NSDictionary+Strategy.h"
#import "KPBrowserViewController.h"
#import "KPPlayerDatasourceHandler.h"
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

@interface KPViewController() <KPIMAAdsPlayerDatasource, KPlayerEventsDelegate>{
    // Player Params
    BOOL isFullScreen, isPlaying, isResumePlayer;
    CGRect originalViewControllerFrame;
    CGAffineTransform fullScreenPlayerTransform;
    UIDeviceOrientation prevOrientation, deviceOrientation;
    NSString *playerSource;
    NSDictionary *appConfigDict;
//    BOOL openFullScreen;
    UIButton *btn;
    BOOL isCloseFullScreenByTap;
    
    // AirPlay Params
    MPVolumeView *volumeView;
    NSArray *prevAirPlayBtnPositionArr;
    
    BOOL isJsCallbackReady;
    
    
    
    BOOL showChromecastBtn;
    
    NSDictionary *nativeActionParams;
    
    NSMutableArray *callBackReadyRegistrations;
    //KPKalturaPlayWithAdsSupport *IMAPlayer;
    NSURL *videoURL;
    NSString *localeString;
}

@property (nonatomic, copy) NSMutableDictionary *kPlayerEventsDict;
@property (nonatomic, copy) NSMutableDictionary *kPlayerEvaluatedDict;
@property (nonatomic, strong) KPShareManager *shareManager;
@property (nonatomic, strong) KPlayerController *playerController;
@property (nonatomic) BOOL isModifiedFrame;
@property (nonatomic) BOOL isFullScreenToggled;
@property (nonatomic) CGRect startFrame;
@property (nonatomic, strong) KPIMAPlayerViewController *imaPlayer;
@end

@implementation KPViewController 
@synthesize webView, player;
@synthesize nativComponentDelegate;

+ (void)setLogLevel:(KPLogLevel)logLevel {
    @synchronized(self) {
        KPLogManager.KPLogLevel = logLevel;
    }
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        videoURL = url;
        return self;
    }
    return nil;
}

- (UIView *)playerViewForParentViewController:(UIViewController *)parentViewController
                                        frame:(CGRect)frame {
    if (parentViewController && [parentViewController isKindOfClass:[UIViewController class]]) {
        _isModifiedFrame = YES;
        [parentViewController addChildViewController:self];
        self.view.frame = frame;
        [self.view addObserver:self
                    forKeyPath:@"frame"
                       options:NSKeyValueObservingOptionNew
                       context:nil];
        return self.view;
    }
    return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.view] && [keyPath isEqualToString:@"frame"]) {
        [self.view.layer.sublayers.firstObject setFrame:(CGRect){CGPointZero, self.view.frame.size}];
        self.webView.frame = (CGRect){CGPointZero, self.view.frame.size};
        [self performSelector:@selector(updateLayout) withObject:nil afterDelay:2];
        
    }
}

- (void)updateLayout {
    self.triggerEvent(@"enterfullscreen", nil);
//    self.triggerEvent(@"updateLayout", nil);
}

- (NSMutableDictionary *)players {
    if (!_players) {
        _players = [NSMutableDictionary new];
    }
    return _players;
}

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

- (void)viewDidLoad {
    KPLogTrace(@"Enter");
    appConfigDict = extractDictionary(AppConfigurationFileName, @"plist");
    setUserAgent();
    [self initPlayerParams];
    // Observer for pause player notifications
    [ [NSNotificationCenter defaultCenter] addObserver: self
                                              selector: @selector(pause)
                                                  name: PlayerPauseNotification
                                                object: nil ];
    
    
    
    
    // Pinch Gesture Recognizer - Player Enter/ Exit FullScreen mode
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(didPinchInOut:)];
    [self.view addGestureRecognizer:pinch];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
//    [self didLoad];
//    [KPViewController sharedChromecastDeviceController];
//    __weak KPViewController *weakSelf = self;
//    [self registerReadyEvent:^{
//        weakSelf.webView.entryId = @"1_gtjr7duj";
//    }];
    
    [super viewDidLoad];
    KPLogTrace(@"Exit");
}


- (void)handleEnteredBackground: (NSNotification *)not {
    KPLogTrace(@"Enter");
    self.sendNotification(nil, @"doPause");
    KPLogTrace(@"Exit");
}



- (void)viewWillAppear:(BOOL)animated {
    KPLogTrace(@"Enter");
    
    if (!_playerController) {
        _playerController = [[KPlayerController alloc] initWithPlayerClassName:PlayerClassName];
        [_playerController addPlayerToView:self.view];
        [_playerController.player setDelegate:self];
    }
    // Initialize HTML layer (controls)
    if (!self.webView) {
        self.webView = [[KPControlsWebView alloc] initWithFrame:(CGRect){CGPointZero, self.view.frame.size}];
        self.webView.playerControlsWebViewDelegate = self;
        [self.webView loadRequest:[NSURLRequest requestWithURL:videoURL]];
        [self.view addSubview:self.webView];
    }
    __weak KPViewController *weakSelf = self;
    [self registerReadyEvent:^{
        if (!weakSelf.isModifiedFrame) {
            weakSelf.setKDPAttribute(@"fullScreenBtn", @"visible", @"false");
        } else {
            
        }
    }];
    self.addEventListener(KPlayerEventToggleFullScreen, @"defaultFS", ^(NSString *eventId) {
        weakSelf.isFullScreenToggled = !self.isFullScreenToggled;
        
        if (weakSelf.isFullScreenToggled) {
            weakSelf.startFrame = self.view.frame;
            weakSelf.view.frame = [UIScreen mainScreen].bounds;
        } else {
            weakSelf.view.frame = weakSelf.startFrame;
        }
        
    });
    [super viewWillAppear:NO];
    
    KPLogTrace(@"Exit");
}

- (void)viewDidDisappear:(BOOL)animated {
    KPLogTrace(@"Enter");
    
    isResumePlayer = YES;
    [super viewDidDisappear:animated];
    
    KPLogTrace(@"Exit");
}

#pragma mark - WebView Methods


- (void)changeMedia:(NSString *)mediaID {
    NSString *name = [NSString stringWithFormat:@"'{\"entryId\":\"%@\"}'", mediaID];
    [self sendNotification:@"changeMedia" forName:name];
}


- (void)load {
    [self.webView loadRequest:[KPPlayerDatasourceHandler videoRequest:self.datasource]];
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


- (void)doNativeAction {
    KPLogTrace(@"Enter");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL nativeAction = NSSelectorFromString(nativeActionParams.actionType);
    [self performSelector:nativeAction withObject:nil];
#pragma clang diagnostic pop
    KPLogTrace(@"Exit");
}

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
        //[self updatePlayerLayout];
        isCloseFullScreenByTap = YES;
        _isFullScreenToggled = YES;
        
        if ( !isFullScreen ) {
            //[self openFullScreen: openFullScreen];
            [self checkDeviceStatus];
        } else{
            //[self closeFullScreen];
        }
    }
    KPLogTrace(@"Exit");
}

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

#pragma mark KPlayerEventsDelegate
- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event value:(NSString *)value {
    if ([event isEqualToString:@"ended"]) {
        [_imaPlayer contentCompleted];
    } 
    [self.webView triggerEvent:event withValue:value];
}


- (void)triggerKPlayerNotification: (NSNotification *)note{
    KPLogTrace(@"Enter");
    isPlaying = note.name.isPlay || (!note.name.isPause && !note.name.isStop);
    [self.webView triggerEvent:note.name withValue:note.userInfo[note.name]];
    KPLogDebug(@"%@\n%@", note.name, note.userInfo[note.name]);
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
            localeString = attributeVal;
            break;
        case doubleClickRequestAds: {
//            [self.player pause];
            __weak KPViewController *weakSelf = self;
             _imaPlayer = [[KPIMAPlayerViewController alloc] initWithParent:self];
            [_imaPlayer loadIMAAd:attributeVal withContentPlayer:_playerController.player eventsListener:^(NSDictionary *adEventParams) {
                if (adEventParams) {
                    [weakSelf.webView triggerEvent:adEventParams.allKeys.firstObject withJSON:adEventParams.allValues.firstObject];
                }
//                if ([adEventParams.allKeys.firstObject isEqualToString:AdCompletedKey]) {
//                    <#statements#>
//                }
                
            }];
            
        }
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

- (void)stopAndRemovePlayer{
    KPLogTrace(@"Enter");
    [self visible:@"false"];
    [[self player] stop];
    [[self player] setContentURL:nil];
    [[[self player] view] removeFromSuperview];
    [[self webView] removeFromSuperview];
    
    if( isFullScreen ){
        isFullScreen = NO;
    }
    
    self.player = nil;
    self.webView = nil;
    
//    [self removeAirPlayIcon];
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
        self.webView.frame = [UIScreen mainScreen].bounds;
        NSLog(@"Screen - %@", NSStringFromCGRect(self.view.frame));
        [self.view.layer.sublayers.firstObject setFrame:self.view.frame];
    }
}



#pragma mark KPIMAAdsPlayerDatasource
- (NSTimeInterval)currentTime {
    return [self.player currentPlaybackTime];
}

- (CGFloat)adPlayerHeight {
    return self.webView.videoHolderHeight;
}

- (NSString *)locale {
    return localeString.copy;
}
@end


