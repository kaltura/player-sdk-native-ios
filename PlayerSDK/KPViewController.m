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

typedef NS_ENUM(NSInteger, KPActionType) {
    KPActionTypeShare,
    KPActionTypeOpenHomePage
};

@interface KPViewController() {
    // Player Params
    BOOL isSeeking;
    BOOL isFullScreen, isPlaying, isResumePlayer;
    CGRect originalViewControllerFrame;
    CGAffineTransform fullScreenPlayerTransform;
    UIDeviceOrientation prevOrientation, deviceOrientation;
    NSString *playerSource;
    NSDictionary *appConfigDict;
    BOOL openFullScreen;
    UIButton *btn;
    BOOL isCloseFullScreenByTap;
    BOOL isFullScreenToggled;
    // AirPlay Params
    MPVolumeView *volumeView;
    NSArray *prevAirPlayBtnPositionArr;
    
    BOOL isJsCallbackReady;
    
    
    
    BOOL *showChromecastBtn;
    
    NSDictionary *nativeActionParams;
    
    NSMutableArray *callBackReadyRegistrations;
}

@property (nonatomic, copy) NSMutableDictionary *kPlayerEventsDict;
@property (nonatomic, copy) NSMutableDictionary *kPlayerEvaluatedDict;
@end

@implementation KPViewController 
@synthesize webView, player;
@synthesize nativComponentDelegate;

- (instancetype)initWithFrame:(CGRect)frame forView:(UIView *)parentView {
    self = [super init];
    if (self) {
        [self.view setFrame:frame];
        originalViewControllerFrame = frame;
        [parentView addSubview:self.view];
        return self;
    }
    return self;
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

- (void)viewDidLoad {
    NSLog(@"View Did Load Enter");
    
    // Adding a suffix to user agent in order to identify native media space application
    setUserAgent();
    [self initPlayerParams];

    appConfigDict = extractDictionary(AppConfigurationFileName, @"plist");
    // Observer for pause player notifications
    [ [NSNotificationCenter defaultCenter] addObserver: self
                                              selector: @selector(pause)
                                                  name: PlayerPauseNotification
                                                object: nil ];
    
    
    
    
    // Pinch Gesture Recognizer - Player Enter/ Exit FullScreen mode
    UIPinchGestureRecognizer *pinch = [ [UIPinchGestureRecognizer alloc] initWithTarget: self action: @selector(didPinchInOut:) ];
    [self.view addGestureRecognizer:pinch];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [self didLoad];
    [KPViewController sharedChromecastDeviceController];
    [super viewDidLoad];
    
    NSLog(@"View Did Load Exit");
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"viewDidAppear Enter");
    
    [super viewDidAppear:animated];
    if( [[NSUserDefaults standardUserDefaults] objectForKey: @"iframe_url"] != nil ) {
        return;
    }
    
    // Before player appears the user must set the kaltura iframe url
    if ( kalPlayerViewControllerDelegate && [kalPlayerViewControllerDelegate respondsToSelector: @selector(getInitialKIframeUrl)] ) {
        NSURL *url = [kalPlayerViewControllerDelegate getInitialKIframeUrl];
        [self setWebViewURL: [NSString stringWithFormat: @"%@", url]];
    } else {
        NSLog( @"Error:: Delegate MUST be set and respond to selector -getInitialKIframeUrl");
        return;
    }
    NSLog(@"viewDidAppear Exit");
}

- (void)handleEnteredBackground: (NSNotification *)not {
    NSLog(@"handleEnteredBackground Enter");
    self.sendNotification(nil, @"doPause");
    NSLog(@"handleEnteredBackground Exit");
}


- (id<KalturaPlayer>)getPlayerByClass: (Class<KalturaPlayer>)class {
    NSString *playerName = NSStringFromClass(class);
    id<KalturaPlayer> newKPlayer = self.players[playerName];
    
    if ( newKPlayer == nil ) {
        newKPlayer = [[class alloc] init];
        self.players[playerName] = newKPlayer;
        // if player is created for the first time add observer to all relevant notifications
        [newKPlayer bindPlayerEvents];
    }
    
    if ( [self player] ) {
        
        NSLog(@"%f", [[self player] currentPlaybackTime]);
        [newKPlayer copyParamsFromPlayer: [self player]];
    }
    
    return newKPlayer;
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear Enter");
    
    CGRect playerViewFrame = CGRectMake( 0, 0, self.view.frame.size.width, self.view.frame.size.height );
    
    if ( !isFullScreen && !isResumePlayer ) {
        self.webView = [ [KPControlsWebView alloc] initWithFrame: playerViewFrame ];
        [[self webView] setPlayerControlsWebViewDelegate: self];
        
        self.player = [self getPlayerByClass:[KalturaPlayer class]];
        NSAssert([self player], @"You MUST initilize and set player in order to make the view work!");

        self.player.view.frame = playerViewFrame;
        
        // WebView initialize for supporting NativeComponent(html5 player view)
        [ [[self webView] scrollView] setScrollEnabled: NO ];
        [ [[self webView] scrollView] setBounces: NO ];
        [ [[self webView] scrollView] setBouncesZoom: NO ];
        self.webView.opaque = NO;
        self.webView.backgroundColor = [UIColor clearColor];
        
        // Add NativeComponent (html5 player view) webView to player view
        [[[self player] view] addSubview: [self webView]];
        [[self view] addSubview: [[self player] view]];
        
        self.player.controlStyle = MPMovieControlStyleNone;
    }
    
    [super viewWillAppear:NO];
    
    NSLog( @"viewWillAppear Exit" );
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog( @"viewDidDisappear Enter" );
    
    isResumePlayer = YES;
    [super viewDidDisappear:animated];
    
    NSLog( @"viewDidDisappear Exit" );
}

#pragma mark - WebView Methods

- (void)setWebViewURL: (NSString *)iframeUrl {
    NSLog( @"setWebViewURL Enter" );
    
    [[NSUserDefaults standardUserDefaults] setObject: iframeUrl forKey:@"iframe_url"];
    
//    iframeUrl = [iframeUrl stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    
    
    /// Add the idfa to the iframeURL
    [ [self webView] loadRequest: [ NSURLRequest requestWithURL: [NSURL URLWithString: iframeUrl] ] ];
    
    NSLog(@"setWebViewURLExit");
}


- (void)load {
    [self.webView loadRequest:[KPPlayerDatasourceHandler videoRequest:self.datasource]];
}


#pragma mark - Player Methods

-(void)initPlayerParams {
    NSLog(@"initPlayerParams Enter");
    
    isFullScreen = NO;
    isPlaying = NO;
    isResumePlayer = NO;
    isFullScreenToggled = NO;
    
    NSLog(@"initPlayerParams Exit");
}

- (void)play {
    NSLog( @"Play Player Enter" );
       
    [[self player] play];
    
    NSLog( @"Play Player Exit" );
}

- (void)pause {
    NSLog(@"Pause Player Enter");
    
    [[self player] pause];
    
    NSLog(@"Pause Player Exit");
}

- (void)stop {
    NSLog(@"Stop Player Enter");
    
    [[self player] stop];
    
    NSLog(@"Stop Player Exit");
}

- (void)doNativeAction {
    switch (nativeActionParams.actionType) {
        case KPActionTypeShare:
            [self share];
            break;
        case KPActionTypeOpenHomePage:
            [self openURL];
            break;
        default:
            break;
    }
}

- (void)share {
    KPShareManager *shareManager = [KPShareManager new];
    shareManager.datasource = nativeActionParams;
    UIViewController *shareController = [shareManager shareWithCompletion:^(KPShareResults result,
                                                                            KPShareError *shareError) {
        
    }];
    [self presentViewController:shareController animated:YES completion:nil];
}

- (void)openURL {
    KPBrowserViewController *browser = [KPBrowserViewController currentBrowser];
    browser.url = nativeActionParams.openURL;
    [self presentViewController:browser animated:YES completion:nil];
}

#pragma Kaltura Player External API - KDP API

- (void)registerReadyEvent:(void (^)())handler {
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
}

- (void(^)(void(^)()))registerReadyEvent {
    __weak KPViewController *weakSelf = self;
    return ^(void(^readyCallback)()){
        [weakSelf registerReadyEvent:readyCallback];
    };
}

- (void)notifyJsReady {
    NSLog(@"notifyJsReady Enter");
    
    isJsCallbackReady = YES;
    NSArray *registrations = callBackReadyRegistrations.copy;
    for (void(^handler)() in registrations) {
        handler();
        [callBackReadyRegistrations removeObject:handler];
    }
    callBackReadyRegistrations = nil;
    NSLog(@"notifyJsReady Exit");
}

- (void)addEventListener:(NSString *)event
                 eventID:(NSString *)eventID
                 handler:(void (^)())handler {
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
    }];
}

- (void(^)(NSString *, NSString *, void(^)()))addEventListener {
    __weak KPViewController *weakSelf = self;
    return ^(NSString *event, NSString *eventID, void(^completion)()){
        [weakSelf addEventListener:event eventID:eventID handler:completion];
    };
}

- (void)notifyKPlayerEvent: (NSArray *)arr {
    NSLog(@"notifyKPlayerEvent Enter");
    
    NSString *eventName = arr[0];
    NSArray *listenersArr = self.kPlayerEventsDict[ eventName ];
    
    if ( listenersArr != nil ) {
        for (NSDictionary *eDict in listenersArr) {
            ((void(^)())eDict.allValues.lastObject)();
        }
    }
    
    NSLog(@"notifyKPlayerEvent Exit");
}


- (void)removeEventListener:(NSString *)event
                    eventID:(NSString *)eventID {
    NSMutableArray *listenersArr = self.kPlayerEventsDict[event];
    if ( listenersArr == nil || [listenersArr count] == 0 ) {
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
}

- (void(^)(NSString *, NSString *))removeEventListener {
    __weak KPViewController *weakSelf = self;
    return ^(NSString *event, NSString *eventID) {
        [weakSelf removeEventListener:event eventID:eventID];
    };
}

- (void)asyncEvaluate:(NSString *)expression
         expressionID:(NSString *)expressionID
              handler:(void(^)(NSString *))handler {
    self.kPlayerEvaluatedDict[expressionID] = handler;
    [self.webView evaluate:expressionID evaluateID:expressionID];
}

- (void(^)(NSString *, NSString *, void(^)(NSString *)))asyncEvaluate {
    __weak KPViewController *weakSelf = self;
    return ^(NSString *expression, NSString *expressionID, void(^handler)(NSString *value)) {
        [weakSelf asyncEvaluate:expression expressionID:expressionID handler:handler];
    };
}

- (void)notifyKPlayerEvaluated: (NSArray *)arr {
    if (arr.count == 2) {
        ((void(^)(NSString *))self.kPlayerEvaluatedDict[arr[0]])(arr[1]);
    }
}

- (void)sendNotification:(NSString *)notification forName:(NSString *)notificationName {
    if ( !notification || [ notification isKindOfClass: [NSNull class] ] ) {
        notification = @"null";
    }
    [self.webView sendNotification:notification withName:notificationName];
}

- (void(^)(NSString *, NSString *))sendNotification {
    __weak KPViewController *weakSelf = self;
    return ^(NSString *notification, NSString *notificationName){
        [weakSelf sendNotification:notification forName:notificationName];
    };
}

- (void)setKDPAttribute:(NSString *)pluginName
           propertyName:(NSString *)propertyName
                  value:(NSString *)value {
    [self.webView setKDPAttribute:pluginName propertyName:propertyName value:value];
}

- (void(^)(NSString *, NSString *, NSString *))setKDPAttribute {
    __weak KPViewController *weakSelf = self;
    return ^(NSString *pluginName, NSString *propertyName, NSString *value) {
        [weakSelf setKDPAttribute:pluginName propertyName:propertyName value:value];
    };
}

- (void)triggerEvent:(NSString *)event withValue:(NSString *)value {
    [self.webView triggerEvent:event withValue:value];
}

- (void(^)(NSString *, NSString *))triggerEvent {
    __weak KPViewController *weakSelf = self;
    return ^(NSString *event, NSString *value){
        [weakSelf triggerEvent:event withValue:value];
    };
}


#pragma mark - Player Layout & Fullscreen Treatment

- (void)updatePlayerLayout {
    NSLog( @"updatePlayerLayout Enter" );
    
    //Update player layout
    //[self.webView updateLayout];
    self.triggerEvent(@"updateLayout", nil);
    // FullScreen Treatment
    [ [NSNotificationCenter defaultCenter] postNotificationName: @"toggleFullscreenNotification"
                                                         object:self
                                                       userInfo: @{IsFullScreenKey: @(isFullScreen)} ];
    
    NSLog( @"updatePlayerLayout Exit" );
}

- (void)setOrientationTransform: (CGFloat) angle{
    NSLog( @"setOrientationTransform Enter" );
    // UIWindow frame in ios 8 different for Landscape mode
    if( isIOS(8) && !isFullScreenToggled ) {
        [self.view setTransform: CGAffineTransformIdentity];
        return;
    }
    
    isFullScreenToggled = NO;
    if ( isFullScreen ) {
        // Init Transform for Fullscreen
        fullScreenPlayerTransform = CGAffineTransformMakeRotation( ( angle * M_PI ) / 180.0f );
        fullScreenPlayerTransform = CGAffineTransformTranslate( fullScreenPlayerTransform, 0.0, 0.0);
        
        self.view.center = [[UIApplication sharedApplication] delegate].window.center;
        [self.view setTransform: fullScreenPlayerTransform];
        
        // Add Mask Support to WebView & Player
        self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
    }else{
        [self.view setTransform: CGAffineTransformIdentity];
    }
    
    NSLog( @"setOrientationTransform Exit" );
}

- (void)checkDeviceStatus{
    NSLog( @"checkDeviceStatus Enter" );
//    deviceOrientation = isDeviceOrientation(UIDeviceOrientationUnknown) ? _statusBarOrientation : _deviceOrientation;
//    if (isIpad || openFullScreen) {
//        switch (deviceOrientation) {
//            case UIDeviceOrientationLandscapeLeft:
//                [self setOrientationTransform: 90];
//                break;
//            case UIDeviceOrientationLandscapeRight:
//                [self setOrientationTransform: -90];
//                break;
//            case UIDeviceOrientationPortrait:
//                [self setOrientationTransform: 180];
//                [self.view setTransform: CGAffineTransformIdentity];
//                break;
//            case UIDeviceOrientationPortraitUpsideDown:
//                [self setOrientationTransform: -180];
//                break;
//            default:
//                break;
//        }
//    } else {
//        BOOL isOneOfOrientations = [DeviceParamsHandler compareOrientation:deviceOrientation
//                                            listOfOrientations:UIDeviceOrientationUnknown,
//                        UIDeviceOrientationPortrait,
//                        UIDeviceOrientationPortraitUpsideDown,
//                        UIDeviceOrientationFaceDown,
//                        UIDeviceOrientationFaceUp];
//        if (isOneOfOrientations) {
//            [self setOrientationTransform: 90];
//        } else {
//            if (isDeviceOrientation(UIDeviceOrientationLandscapeLeft)) {
//                [self setOrientationTransform: 90];
//            } else if (isDeviceOrientation(UIDeviceOrientationLandscapeRight)){
//                [self setOrientationTransform: -90];
//            }
//        }
//    }
    
    deviceOrientation = [[UIDevice currentDevice] orientation];
    if ( isIpad || openFullScreen ) {
        if (deviceOrientation == UIDeviceOrientationUnknown) {
            if ( _statusBarOrientation == UIDeviceOrientationLandscapeLeft ) {
                [self setOrientationTransform: 90];
            }else if(_statusBarOrientation == UIDeviceOrientationLandscapeRight){
                [self setOrientationTransform: -90];
            }else if(_statusBarOrientation == UIDeviceOrientationPortrait){
                [self setOrientationTransform: 180];
                [self.view setTransform: CGAffineTransformIdentity];
            }else if (_statusBarOrientation == UIDeviceOrientationPortraitUpsideDown){
                [self setOrientationTransform: -180];
            }
        }else{
            if ( deviceOrientation == UIDeviceOrientationLandscapeLeft ) {
                [self setOrientationTransform: 90];
            }else if(deviceOrientation == UIDeviceOrientationLandscapeRight){
                [self setOrientationTransform: -90];
            }else if(deviceOrientation == UIDeviceOrientationPortrait){
                [self setOrientationTransform: 180];
                [self.view setTransform: CGAffineTransformIdentity];
            }else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown){
                [self setOrientationTransform: -180];
            }
        }
    }else{
        if (deviceOrientation == UIDeviceOrientationUnknown ||
            deviceOrientation == UIDeviceOrientationPortrait ||
            deviceOrientation == UIDeviceOrientationPortraitUpsideDown ||
            deviceOrientation == UIDeviceOrientationFaceDown ||
            deviceOrientation == UIDeviceOrientationFaceUp) {
            [self setOrientationTransform: 90];
        }else{
            if ( deviceOrientation == UIDeviceOrientationLandscapeLeft ) {
                [self setOrientationTransform: 90];
            }else if( deviceOrientation == UIDeviceOrientationLandscapeRight ){
                [self setOrientationTransform: -90];
            }
        }
    }
    
    NSLog( @"checkDeviceStatus Exit" );
}

- (void)checkOrientationStatus{
    NSLog( @"checkOrientationStatus Enter" );
    isCloseFullScreenByTap = NO;
    
    // Handle rotation issues when player is playing
    if ( isPlaying ) {
        [self closeFullScreen];
        [self openFullScreen: openFullScreen];
        if ( isFullScreen ) {
            [self checkDeviceStatus];
        }
        
        if ( !isIpad && (deviceOrientation == UIDeviceOrientationPortrait || deviceOrientation == UIDeviceOrientationPortraitUpsideDown) ) {
            if ( !openFullScreen ) {
                [self closeFullScreen];
            }
        }
    }else {
        [self closeFullScreen];
    }
    
    NSLog( @"checkOrientationStatus Exit" );
}

- (void)setNativeFullscreen {
    [UIApplication sharedApplication].statusBarHidden = YES;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    // Disable fullscreen button if the player is set to fullscreen by default
    self.registerReadyEvent(^{
        if ([self respondsToSelector:@selector(setKDPAttribute:propertyName:value:)]) {
            //self.setKDPAttribute(@"fullScreenBtn", @"visible", @"false");
        }
    });
}

- (void)deviceOrientationDidChange {
    CGRect mainFrame;
    
    if ( _deviceOrientation == UIDeviceOrientationFaceDown || _deviceOrientation == UIDeviceOrientationFaceUp ) {
        return;
    }
    
    if ( isIOS(8) ) {
        mainFrame = CGRectMake( screenOrigin.x, screenOrigin.y, screenSize.width, screenSize.height ) ;
    } else if(UIDeviceOrientationIsLandscape(_deviceOrientation)){
        mainFrame = CGRectMake( screenOrigin.x, screenOrigin.y, screenSize.height, screenSize.width ) ;
    } else {
        mainFrame = CGRectMake( screenOrigin.x, screenOrigin.y, screenSize.width, screenSize.height ) ;
    }
    
    [self.view setFrame: mainFrame];
    
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    [self.player.view setFrame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.webView setFrame: self.player.view.frame];
    [ self.view setTransform: fullScreenPlayerTransform ];
    self.triggerEvent(@"enterfullscreen", nil);
    self.triggerEvent(@"updateLayout", nil);
    [self checkDeviceStatus];
}

- (void)openFullscreen {
    if ( !isFullScreen ) {
        [self toggleFullscreen];
    }
}

- (void)closeFullscreen {
    if ( isFullScreen ) {
        [self toggleFullscreen];
    }
}

- (void)toggleFullscreen {
    if (self.kPlayerEventsDict[KPlayerEventToggleFullScreen]) {
        NSArray *listenersArr = self.kPlayerEventsDict[ KPlayerEventToggleFullScreen ];
        
        if ( listenersArr != nil ) {
            for (NSDictionary *eDict in listenersArr) {
                ((void(^)())eDict.allValues.lastObject)();
            }
        }
    } else {
        [self updatePlayerLayout];
        NSLog( @"toggleFullscreen Enter" );
        
        isCloseFullScreenByTap = YES;
        isFullScreenToggled = YES;
        
        if ( !isFullScreen ) {
            [self openFullScreen: openFullScreen];
            [self checkDeviceStatus];
        } else{
            [self closeFullScreen];
        }
        
        NSLog( @"toggleFullscreen Exit" );
    }
}

- (void)openFullScreen: (BOOL)openFullscreen{
    NSLog( @"openFullScreen Enter" );
    
    isFullScreen = YES;
    
    CGRect mainFrame;
    openFullScreen = openFullscreen;
    
    if ( isIpad || openFullscreen ) {
        if ( isDeviceOrientation(UIDeviceOrientationUnknown) ) {
            if (UIDeviceOrientationPortrait == _statusBarOrientation || UIDeviceOrientationPortraitUpsideDown == _statusBarOrientation) {
                mainFrame = CGRectMake( screenOrigin.x, screenOrigin.y, screenSize.width, screenSize.height ) ;
            }else if(UIDeviceOrientationIsLandscape(_statusBarOrientation)){
                mainFrame = CGRectMake( screenOrigin.x, screenOrigin.y, screenSize.height, screenSize.width ) ;
            }
        }else{
            if ( UIDeviceOrientationPortrait == _deviceOrientation || UIDeviceOrientationPortraitUpsideDown == _deviceOrientation ) {
                mainFrame = CGRectMake( screenOrigin.x, screenOrigin.y, screenSize.width, screenSize.height ) ;
            }else if(UIDeviceOrientationIsLandscape(_deviceOrientation)){
                mainFrame = CGRectMake( screenOrigin.x, screenOrigin.y, screenSize.height, screenSize.width ) ;
            }
        }
    }else{
        mainFrame = CGRectMake( screenOrigin.x, screenOrigin.y, screenSize.height, screenSize.width ) ;
    }
    
    [self.view setFrame: mainFrame];
    
    [UIApplication sharedApplication].statusBarHidden = YES;

    [self.player.view setFrame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.webView setFrame: self.player.view.bounds];
    [ self.view setTransform: fullScreenPlayerTransform ];
    
    self.triggerEvent(@"enterfullscreen", nil);
    [self updatePlayerLayout];
    NSLog( @"openFullScreen Exit" );
}

- (void)closeFullScreen{
    NSLog( @"closeFullScreen Enter" );
    
    if ( openFullScreen && isCloseFullScreenByTap ) {
//        [self stop];
    }
    
    CGRect originalFrame = CGRectMake( 0, 0, originalViewControllerFrame.size.width, originalViewControllerFrame.size.height );
    isFullScreen = NO;
    
    [self.view setTransform: CGAffineTransformIdentity];
    self.view.frame = originalViewControllerFrame;
    self.player.view.frame = originalFrame;
    self.webView.frame = [[[self player] view] frame];
    
    [UIApplication sharedApplication].statusBarHidden = NO;
    
    self.triggerEvent(@"exitfullscreen", nil);
    [self updatePlayerLayout];
    
    NSLog( @"closeFullScreen Exit" );
}

// "pragma clang" is attached to prevent warning from “PerformSelect may cause a leak because its selector is unknown”
- (void)handleHtml5LibCall:(NSString*)functionName callbackId:(int)callbackId args:(NSArray*)args{
    NSLog(@"handleHtml5LibCall Enter");
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ( [args count] > 0 ) {
        functionName = [NSString stringWithFormat:@"%@:", functionName];
    }
    if ([self respondsToSelector:NSSelectorFromString(functionName)]) {
        [self performSelector:NSSelectorFromString(functionName) withObject:args];
    }
    
#pragma clang diagnostic pop
    
    NSLog(@"handleHtml5LibCall Exit");
}

- (void)bindPlayerEvents{
    NSLog(@"Binding Events Enter");
    
    if ( self ) {
//        [[self player] bindPlayerEvents];
        NSArray *kPlayerEvents = @[@"canplay",
                                   @"durationchange",
                                   @"loadedmetadata",
                                   @"play",
                                   @"pause",
                                   @"ended",
                                   @"seeking",
                                   @"seeked",
                                   @"timeupdate",
                                   @"progress",
                                   @"fetchNativeAdID"];
        
        for (id kPlayerEvent in kPlayerEvents) {
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                      selector: @selector(triggerKPlayerNotification:)
                                                          name: kPlayerEvent
                                                        object: nil];
        }
    }
    
    NSLog(@"Binding Events Exit");
}

- (void)triggerKPlayerNotification: (NSNotification *)note{
    NSLog(@"triggerLoadPlabackEvents Enter");
    
    isPlaying = note.name.isPlay || (!note.name.isPause && !note.name.isStop);
    [self.webView triggerEvent:note.name withValue:note.userInfo[note.name]];
    NSLog(@"triggerLoadPlabackEvents Exit");
}

- (void)setAttribute: (NSArray*)args{
    NSLog(@"setAttribute Enter");
    
    NSString *attributeName = [args objectAtIndex:0];
    NSString *attributeVal = args[1];
    
    switch ( attributeName.attributeEnumFromString ) {
        case src:
            playerSource = attributeVal;
            [ self setPlayerSource: [NSURL URLWithString: attributeVal] ];
            break;
        case currentTime:
            if( [[self player] isPreparedToPlay] ){
                [ [self player] setCurrentPlaybackTime: [attributeVal doubleValue] ];
            }
            break;
        case visible:
            [self visible: attributeVal];
            break;
#if !(TARGET_IPHONE_SIMULATOR)
        case wvServerKey:
            if ( [[self player] respondsToSelector:@selector(setWideVideConfigurations)] ) {
                [[self player] setWideVideConfigurations];
            }
            if ( [[self player] respondsToSelector:@selector(initWV:andKey:)]) {
                [[self player] initWV: playerSource andKey: attributeVal];
            }

            break;
#endif
        case nativeAction:
            nativeActionParams = [NSJSONSerialization JSONObjectWithData:[attributeVal dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:nil];
            break;
        default:
            break;
    }
    NSLog(@"setAttribute Exit");
}

- (void)setPlayerSource: (NSURL *)src{
    NSLog(@"setPlayerSource Enter");
    [[self player] setContentURL:src];
    
    NSLog(@"setPlayerSource Exit");
}

- (void)resizePlayerView:(CGRect)newFrame {
    originalViewControllerFrame = newFrame;
    if ( !isFullScreen ) {
        self.view.frame = originalViewControllerFrame;
        self.player.view.frame = newFrame;
        self.webView.frame = self.player.view.frame;
    }
}

- (void)setPlayerFrame:(CGRect)playerFrame {
    if ( !isFullScreen ) {
        self.view.frame = playerFrame;
        self.player.view.frame = CGRectMake( 0, 0, playerFrame.size.width, playerFrame.size.height );
        self.webView.frame = self.player.view.frame;
    }
}

-(void)visible:(NSString *)boolVal{
    NSLog(@"visible Enter");
    
    self.triggerEvent(@"visible", [NSString stringWithFormat:@"%@", boolVal]);
    
    NSLog(@"visible Exit");
}

- (void)stopAndRemovePlayer{
    NSLog(@"stopAndRemovePlayer Enter");
    
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
    
    [self removeAirPlayIcon];
    
    NSLog(@"stopAndRemovePlayer Exit");
}

- (void)removeAirPlayIcon {
    NSLog(@"removeAirPlayIcon Enter");
    
    if ( volumeView ) {
        [volumeView removeFromSuperview];
        volumeView = nil;
    }
    
    NSLog(@"removeAirPlayIcon Exit");
}

- (void)doneFSBtnPressed {
    NSLog(@"doneFSBtnPressed Enter");
    
    isCloseFullScreenByTap = YES;
    [self closeFullScreen];
    
    NSLog(@"doneFSBtnPressed Exit");
}

#pragma mark - airplay plugin
- (void)addNativeAirPlayButton {
    NSLog(@"addNativeAirPlayButton Enter");
    
    // Add airplay
    self.view.backgroundColor = [UIColor clearColor];
    if ( !volumeView ) {
        volumeView = [ [MPVolumeView alloc] init ];
        [volumeView setShowsVolumeSlider: NO];
    }
    
    NSLog(@"addNativeAirPlayButton Exit");
}

-(void)showNativeAirPlayButton: (NSArray*)airPlayBtnPositionArr {
    NSLog(@"showNativeAirPlayButton Enter");
    
    if ( volumeView.hidden ) {
        volumeView.hidden = NO;
        
        if ( prevAirPlayBtnPositionArr == nil || ![prevAirPlayBtnPositionArr isEqualToArray: airPlayBtnPositionArr] ) {
            prevAirPlayBtnPositionArr = airPlayBtnPositionArr;
        }else {
            return;
        }
    }
    
    CGFloat x = [[airPlayBtnPositionArr objectAtIndex:0] floatValue];
    CGFloat y = [[airPlayBtnPositionArr objectAtIndex:1] floatValue];
    CGFloat w = [[airPlayBtnPositionArr objectAtIndex:2] floatValue];
    CGFloat h = [[airPlayBtnPositionArr objectAtIndex:3] floatValue];
    
    volumeView.frame = CGRectMake( x, y, w, h );
    
    [self.view addSubview: volumeView];
    [self.view bringSubviewToFront: volumeView];
    
    NSLog(@"showNativeAirPlayButton Exit");
}

- (void)switchPlayer:(Class)p {
    [[self player] stop];
    self.player = [self getPlayerByClass: p];
    
//    if ( [self.player isPreparedToPlay] ) {
//        [self.player play];
//    }
}

-(void)showChromecastDeviceList {
    NSLog(@"showChromecastDeviceList Enter");
    
    [ [KPViewController sharedChromecastDeviceController] chooseDevice: self];
    
    NSLog(@"showChromecastDeviceList Exit");
}

-(void)hideNativeAirPlayButton {
    NSLog(@"hideNativeAirPlayButton Enter");
    
    if ( !volumeView.hidden ) {
        volumeView.hidden = YES;
    }
    
    NSLog(@"hideNativeAirPlayButton Exit");
}

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


#pragma mark -

-(void)didPinchInOut:(UIPinchGestureRecognizer *) recongizer {
    NSLog( @"didPinchInOut Enter" );
    
    if (isFullScreen && recongizer.scale < 1) {
        [self toggleFullscreen];
    } else if (!isFullScreen && recongizer.scale > 1) {
        [self toggleFullscreen];
    }
    
    NSLog( @"didPinchInOut Exit" );
}

- (void)didConnectToDevice:(GCKDevice*)device {
    [self switchPlayer: [KPChromecast class]];
    self.triggerEvent(@"chromecastDeviceConnected", nil);
}

- (void)didReceiveMediaStateChange {
    if (![self.player isKindOfClass:[KPChromecast class]]) {
        return;
    }
    
    KPChromecast *chromecastPlayer = (KPChromecast *) self.player;
    
    if ( [[KPViewController sharedChromecastDeviceController] playerState] == GCKMediaPlayerStatePlaying ) {
        [chromecastPlayer triggerMediaNowPlaying];
//        [self triggerEventsJavaScript: @"play" WithValue: nil];
    } else if ( [[KPViewController sharedChromecastDeviceController] playerState] == GCKMediaPlayerStatePaused ) {
        [chromecastPlayer triggerMediaNowPaused];
    }
}

// Chromecast
- (void)didLoad {
    showChromecastBtn = NO;
    [[KPViewController sharedChromecastDeviceController] performScan: YES];
}

+ (id)sharedChromecastDeviceController {
    static ChromecastDeviceController *chromecastDeviceController = nil;
    static dispatch_once_t onceToken;

    dispatch_once( &onceToken, ^{
       chromecastDeviceController = [[ChromecastDeviceController alloc] init];
    });
    
    return chromecastDeviceController;
}

- (void)didDiscoverDeviceOnNetwork {
    if ( [[[KPViewController sharedChromecastDeviceController] deviceScanner] devices] ) {
        showChromecastBtn = YES;
    }
}

-(void)notifyLayoutReady {
    [self setChromecastVisiblity];
}

- (void)setChromecastVisiblity {
    if ( [self respondsToSelector: @selector(setKDPAttribute:propertyName:value:)] ) {
        self.setKDPAttribute(@"chromecast", @"visible", showChromecastBtn ? @"true": @"false");
    }
}

- (void)didDisconnect {
    [self switchPlayer: [KalturaPlayer class]];
    self.triggerEvent(@"chromecastDeviceDisConnected", nil);
}


@end


