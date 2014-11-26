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

#import "KPViewController.h"
#import "KPEventListener.h"
#import "KPShareManager.h"
#import "NSDictionary+Strategy.h"

typedef NS_ENUM(NSInteger, KPActionType) {
    KPActionTypeShare
};

@implementation KPViewController {
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
    // AirPlay Params
    MPVolumeView *volumeView;
    NSArray *prevAirPlayBtnPositionArr;
    
    BOOL isJsCallbackReady;
    NSMutableDictionary *kPlayerEventsDict;
    NSMutableDictionary *kPlayerEvaluatedDict;
    
    BOOL *showChromecastBtn;
    
    NSDictionary *nativeActionParams;
}

@synthesize webView, player;
@synthesize nativComponentDelegate;
@synthesize jsCallbackReadyHandler;

- (instancetype)initWithFrame:(CGRect)frame forView:(UIView *)parentView {
    self = [super init];
    [self.view setFrame:frame];
    originalViewControllerFrame = frame;
    [parentView addSubview:self.view];
    return self;
}

- (void)viewDidLoad {
    NSLog(@"View Did Load Enter");
    
    self.players = [NSMutableDictionary new];
    
    // Adding a suffix to user agent in order to identify native media space application
    NSString* suffixUA = @"kalturaNativeCordovaPlayer";
    UIWebView* wv = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString* defaultUA = [wv stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    NSString* finalUA = [defaultUA stringByAppendingString:suffixUA];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:finalUA, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];

    [self initPlayerParams];
    
    appConfigDict = [NSDictionary dictionaryWithContentsOfFile: [ [NSBundle mainBundle] pathForResource: @"AppConfigurations" ofType: @"plist"]];
    
    // Kaltura KDP API Listeners Dictionary
    kPlayerEventsDict = [NSMutableDictionary new];
    kPlayerEvaluatedDict = [NSMutableDictionary new];
    
    // Observer for pause player notifications
    [ [NSNotificationCenter defaultCenter] addObserver: self
                                              selector: @selector(pause)
                                                  name: @"playerPauseNotification"
                                                object: nil ];
    
    // Pinch Gesture Recognizer - Player Enter/ Exit FullScreen mode
    UIPinchGestureRecognizer *pinch = [ [UIPinchGestureRecognizer alloc] initWithTarget: self action: @selector(didPinchInOut:) ];
    [self.view addGestureRecognizer:pinch];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [self didLoad];
    [[KPViewController sharedChromecastDeviceController] setDelegate: self];
    
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
        @throw [NSException exceptionWithName:NSGenericException reason:@"Delegate MUST be set and respond to selector -getInitialKIframeUrl !" userInfo:nil];
        return;
    }
    
    NSLog(@"viewDidAppear Exit");
}

- (void)handleEnteredBackground: (NSNotification *)not {
    NSLog(@"handleEnteredBackground Enter");
    
    [self sendNotification: @"doPause" andNotificationBody: nil];
    
    NSLog(@"handleEnteredBackground Exit");
}

- (id<KalturaPlayer>)getPlayerByClass: (Class<KalturaPlayer>)class {
    NSString *playerName = NSStringFromClass(class);
    id<KalturaPlayer> newKPlayer = [[self players] objectForKey:playerName];
    
    if ( newKPlayer == nil ) {
        newKPlayer = [[class alloc] init];
        [[self players] setObject: newKPlayer forKey: playerName];
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
    [ [self webView] loadRequest: [ NSURLRequest requestWithURL: [NSURL URLWithString: iframeUrl] ] ];
    
    NSLog(@"setWebViewURLExit");
}

- (NSString*)writeJavascript: (NSString*)javascript {
    NSLog(@"writeJavascript: %@", javascript);
    
    return [[self webView] stringByEvaluatingJavaScriptFromString: javascript];
}

#pragma mark - Player Methods

-(void)initPlayerParams {
    NSLog(@"initPlayerParams Enter");
    
    isFullScreen = NO;
    isPlaying = NO;
    isResumePlayer = NO;
    
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

#pragma Kaltura Player External API - KDP API

- (void)registerJSCallbackReady: (JSCallbackReadyHandler)handler {
    NSLog(@"registerJSCallbackReady Enter");

    if ( isJsCallbackReady ) {
        handler();
    } else {
        jsCallbackReadyHandler = handler;
    }
    
    NSLog(@"registerJSCallbackReady Exit");
}

- (void)notifyJsReady {
    NSLog(@"notifyJsReady Enter");
    
    isJsCallbackReady = YES;
    
    if ( jsCallbackReadyHandler ) {
        jsCallbackReadyHandler();
        jsCallbackReadyHandler = nil;
    }
    
    NSLog(@"notifyJsReady Exit");
}

- (void)addKPlayerEventListener: (NSString *)name forListener: (KPEventListener *)listener {
    NSLog(@"addKPlayerEventListener Enter");
    
    NSMutableArray *listenersArr = [kPlayerEventsDict objectForKey: name];
    
    if ( listenersArr == nil ) {
        listenersArr = [NSMutableArray new];
    }
    
    [listenersArr addObject: listener];
    [kPlayerEventsDict setObject: listenersArr forKey: name];
    
    if ( [listenersArr count] == 1 ) {
         [ self writeJavascript: [NSString stringWithFormat: @"NativeBridge.videoPlayer.addJsListener(\"%@\");", name] ];
    }
    
    NSLog(@"addKPlayerEventListener Exit");
}

- (void)notifyKPlayerEvent: (NSArray *)arr {
    NSLog(@"notifyKPlayerEvent Enter");
    
    NSString *eventName = [arr objectAtIndex: 0];
    NSArray *listenersArr = [ kPlayerEventsDict objectForKey: eventName ];
    
    if ( listenersArr != nil ) {
        for (KPEventListener *e in listenersArr) {
            e.eventListener(nil);
        }
    }
    
    NSLog(@"notifyKPlayerEvent Exit");
}
- (void)removeKPlayerEventListenerWithEventName: (NSString *)eventName forListenerName: (NSString *)listenerName {
    NSLog(@"removeKPlayerEventListenerWithName Enter");
    
    NSMutableArray *listenersArr = [kPlayerEventsDict objectForKey: eventName];
    
    if ( listenersArr == nil || [listenersArr count] == 0 ) {
        return;
    }

    for ( KPEventListener *e in listenersArr ) {
        if ( [e.name isEqualToString: listenerName] ) {
            [listenersArr removeObject: e];
            break;
        }
    }
    
    if ( [listenersArr count] == 0 ) {
        listenersArr = nil;
    }
    
    if ( listenersArr == nil ) {
        [self writeJavascript: [NSString stringWithFormat: @"NativeBridge.videoPlayer.removeJsListener(\"%@\");", eventName]];
    }
    
    NSLog(@"removeKPlayerEventListenerWithName Exit");
}

- (void)asyncEvaluate: (NSString *)expression forListener: (KPEventListener *)listener {
    NSLog(@"asyncEvaluate Enter");
    
    [kPlayerEvaluatedDict setObject: listener forKey: [listener name]];
    [self writeJavascript: [NSString stringWithFormat: @"NativeBridge.videoPlayer.asyncEvaluate(\"%@\", \"%@\");", expression, [listener name]]];
    
    NSLog(@"asyncEvaluate Exit");
}

- (void) notifyKPlayerEvaluated: (NSArray *)arr {
    NSLog(@"notifyKPlayerEvaluated Enter");
    
    KPEventListener *listener = [kPlayerEvaluatedDict objectForKey: [arr objectAtIndex: 0] ];
    listener.eventListener( [arr objectAtIndex: 1] );
    
    NSLog(@"notifyKPlayerEvaluated Exit");
}

- (void)sendNotification: (NSString*)notificationName andNotificationBody: (NSString *)notificationBody {
    NSLog(@"sendNotification Enter");
    
    if ( notificationBody == nil || [ notificationBody isKindOfClass: [NSNull class] ] ) {
        notificationBody = @"null";
    }
    
    [self writeJavascript: [NSString stringWithFormat:@"NativeBridge.videoPlayer.sendNotification(\"%@\" ,%@);", notificationName, notificationBody]];
    
    NSLog(@"sendNotification Exit");
}

- (void)setKDPAttribute: (NSString*)pluginName propertyName: (NSString*)propertyName value: (NSString*)value {
    NSLog(@"setKDPAttribute Enter");
    
    NSString *kdpAttributeStr = [NSString stringWithFormat: @"NativeBridge.videoPlayer.setKDPAttribute('%@','%@', %@);", pluginName, propertyName, value];
    [self writeJavascript: kdpAttributeStr];
 
    NSLog(@"setKDPAttribute Exit");
}

#pragma mark - Player Layout & Fullscreen Treatment

- (void)updatePlayerLayout {
    NSLog( @"updatePlayerLayout Enter" );
    
    //Update player layout
    NSString *updateLayoutJS = @"document.getElementById( this.id ).doUpdateLayout();";
    [self writeJavascript: updateLayoutJS];
    
    // FullScreen Treatment
    NSDictionary *fullScreenDataDict = [ NSDictionary dictionaryWithObject: [NSNumber numberWithBool: isFullScreen]
                                                                    forKey: @"isFullScreen" ];
    [ [NSNotificationCenter defaultCenter] postNotificationName: @"toggleFullscreenNotification"
                                                         object:self
                                                       userInfo: fullScreenDataDict ];
    
    NSLog( @"updatePlayerLayout Exit" );
}

- (void)setOrientationTransform: (CGFloat) angle{
    NSLog( @"setOrientationTransform Enter" );
    
    // UIWindow frame in ios 8 different for Landscape mode
    if( [self isIOS8] ) {
        [self.view setTransform: CGAffineTransformIdentity];
        return;
    }
    
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
    
    deviceOrientation = [[UIDevice currentDevice] orientation];
    
    if ( [self isIpad] || openFullScreen ) {
        if (deviceOrientation == UIDeviceOrientationUnknown) {
            if ( [UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeLeft ) {
                [self setOrientationTransform: 90];
            }else if([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationLandscapeRight){
                [self setOrientationTransform: -90];
            }else if([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationPortrait){
                [self setOrientationTransform: 180];
                [self.view setTransform: CGAffineTransformIdentity];
            }else if ([UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationPortraitUpsideDown){
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
        
        if ( ![self isIpad] && (deviceOrientation == UIDeviceOrientationPortrait || deviceOrientation == UIDeviceOrientationPortraitUpsideDown) ) {
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)deviceOrientationDidChange {
    CGRect mainFrame;
    
    if ( [[UIDevice currentDevice] orientation] == UIDeviceOrientationFaceDown || [[UIDevice currentDevice] orientation] == UIDeviceOrientationFaceUp ) {
        return;
    }
    
    if ( [self isIOS8] ) {
        mainFrame = CGRectMake( [[UIScreen mainScreen] bounds].origin.x, [[UIScreen mainScreen] bounds].origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height ) ;
    } else if(UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])){
        mainFrame = CGRectMake( [[UIScreen mainScreen] bounds].origin.x, [[UIScreen mainScreen] bounds].origin.y, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width ) ;
    } else {
        mainFrame = CGRectMake( [[UIScreen mainScreen] bounds].origin.x, [[UIScreen mainScreen] bounds].origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height ) ;
    }
    
    [self.view setFrame: mainFrame];
    
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    [self.player.view setFrame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.webView setFrame: self.player.view.frame];
    [ self.view setTransform: fullScreenPlayerTransform ];
    
    [self triggerEventsJavaScript: @"enterfullscreen" WithValue: nil];
    [self updatePlayerLayout];
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
    NSLog( @"toggleFullscreen Enter" );
    
    isCloseFullScreenByTap = YES;
    
    if ( !isFullScreen ) {
        [self openFullScreen: openFullScreen];
        [self checkDeviceStatus];
    } else{
        [self closeFullScreen];
    }
    
    NSLog( @"toggleFullscreen Exit" );
}

- (void)openFullScreen: (BOOL)openFullscreen{
    NSLog( @"openFullScreen Enter" );
    
    isFullScreen = YES;
    
    CGRect mainFrame;
    openFullScreen = openFullscreen;
    
    if ( [self isIpad] || openFullscreen ) {
        if ( [[UIDevice currentDevice] orientation] == UIDeviceOrientationUnknown ) {
            if (UIDeviceOrientationPortrait == [UIApplication sharedApplication].statusBarOrientation || UIDeviceOrientationPortraitUpsideDown == [UIApplication sharedApplication].statusBarOrientation) {
                mainFrame = CGRectMake( [[UIScreen mainScreen] bounds].origin.x, [[UIScreen mainScreen] bounds].origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height ) ;
            }else if(UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)){
                mainFrame = CGRectMake( [[UIScreen mainScreen] bounds].origin.x, [[UIScreen mainScreen] bounds].origin.y, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width ) ;
            }
        }else{
            if ( UIDeviceOrientationPortrait == [[UIDevice currentDevice] orientation] || UIDeviceOrientationPortraitUpsideDown == [[UIDevice currentDevice] orientation] ) {
                mainFrame = CGRectMake( [[UIScreen mainScreen] bounds].origin.x, [[UIScreen mainScreen] bounds].origin.y, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height ) ;
            }else if(UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])){
                mainFrame = CGRectMake( [[UIScreen mainScreen] bounds].origin.x, [[UIScreen mainScreen] bounds].origin.y, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width ) ;
            }
        }
    }else{
        mainFrame = CGRectMake( [[UIScreen mainScreen] bounds].origin.x, [[UIScreen mainScreen] bounds].origin.y, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width ) ;
    }
    
    [self.view setFrame: mainFrame];
    
    [UIApplication sharedApplication].statusBarHidden = YES;

    [self.player.view setFrame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.webView setFrame: self.player.view.frame];
    [ self.view setTransform: fullScreenPlayerTransform ];
    
    [self triggerEventsJavaScript: @"enterfullscreen" WithValue: nil];
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
    
    [self triggerEventsJavaScript:@"exitfullscreen" WithValue:nil];
    
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
    [self performSelector:NSSelectorFromString(functionName) withObject:args];
#pragma clang diagnostic pop
    
    NSLog(@"handleHtml5LibCall Exit");
}

- (void)bindPlayerEvents{
    NSLog(@"Binding Events Enter");
    
    if ( self ) {
//        [[self player] bindPlayerEvents];
        
       NSArray *kPlayerEvents = [NSArray arrayWithObjects: @"canplay", @"durationchange", @"loadedmetadata", @"play", @"pause", @"ended", @"seeking", @"seeked", @"timeupdate", @"progress", nil];
        
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
    
    if( [[note name]  isEqual: @"play"] ) {
        isPlaying = YES;
    }
    
    if ([[note name]  isEqual: @"pause"] || [[note name]  isEqual: @"stop"] ) {
        isPlaying = NO;
    }
    
    [self triggerEventsJavaScript: [note name] WithValue: [[note userInfo] valueForKey: [note name]]];
    
    NSLog(@"triggerLoadPlabackEvents Exit");
}

- (void)triggerEventsJavaScript: (NSString *)eventName WithValue: (NSString *) eventValue{
    NSLog(@"triggerEventsJavaScript Enter");
    
    NSString* jsStringLog = [NSString stringWithFormat:@"trigger --> NativeBridge.videoPlayer.trigger('%@', '%@')", eventName, eventValue];
    NSLog(@"%@", jsStringLog);
    NSString* jsString = [NSString stringWithFormat:@"NativeBridge.videoPlayer.trigger('%@', '%@')", eventName,eventValue];
    [self writeJavascript: jsString];
    NSLog(@"triggerEventsJavaScript Exit");
}

- (void)setAttribute: (NSArray*)args{
    NSLog(@"setAttribute Enter");
    
    NSString *attributeName = [args objectAtIndex:0];
    Attribute attributeValue = [attributeName attributeNameEnumFromString];
    NSString *attributeVal = args[1];
    
    switch ( attributeValue ) {
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
            nativeActionParams = [NSJSONSerialization JSONObjectWithData:[attributeVal dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
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

- (void)resizePlayerView: (CGFloat)top right:(CGFloat)right width:(CGFloat)width height:(CGFloat)height{
    NSLog(@"resizePlayerView Enter");
    
    originalViewControllerFrame = CGRectMake( top, right, width, height );
    
    if ( !isFullScreen ) {
        self.view.frame = originalViewControllerFrame;
        self.player.view.frame = CGRectMake( 0, 0, width, height );
        self.webView.frame = self.player.view.frame;
    }
    
    NSLog(@"resizePlayerView Exit");
}

-(void)visible:(NSString *)boolVal{
    NSLog(@"visible Enter");
    
    [self triggerEventsJavaScript:@"visible" WithValue:[NSString stringWithFormat:@"%@", boolVal]];
    
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

- (BOOL)isIpad{
    
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

- (BOOL)isIOS7{
    
    NSArray *vComp = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    
    if ([[vComp objectAtIndex:0] intValue] == 7) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isIOS8{
    
    NSArray *vComp = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    
    if ([[vComp objectAtIndex:0] intValue] == 8) {
        return YES;
    }
    
    return NO;
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
    [self triggerEventsJavaScript: @"chromecastDeviceConnected" WithValue: nil];
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
        [self setKDPAttribute: @"chromecast" propertyName: @"visible" value: showChromecastBtn ? @"true": @"false"];
    }
}

- (void)didDisconnect {
    [self switchPlayer: [KalturaPlayer class]];
    [self triggerEventsJavaScript: @"chromecastDeviceDisConnected" WithValue: nil];
}

@end

@implementation NSString (EnumParser)

- (Attribute)attributeNameEnumFromString{
    NSLog(@"attributeNameEnumFromString Enter");
    
    NSDictionary *Attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInteger:src], @"src",
                                [NSNumber numberWithInteger:currentTime], @"currentTime",
#if !(TARGET_IPHONE_SIMULATOR)
                                [NSNumber numberWithInteger:wvServerKey], @"wvServerKey",
#endif
                                [NSNumber numberWithInteger:nativeAction], @"nativeAction",
                                nil
                                ];
    NSLog(@"attributeNameEnumFromString Exit");
    return (Attribute)[[Attributes objectForKey:self] intValue];
}

@end
