//
//  PlayerViewController.m
//  HelloWorld
//
//  Created by Eliza Sapir on 9/11/13.
//
//

// Copyright (c) 2013 Kaltura, Inc. All rights reserved.
// License: http://corp.kaltura.com/terms-of-use
//

#import "PlayerViewController.h"

@implementation PlayerViewController{
    BOOL isSeeking;
    BOOL isFullScreen, isPlaying, isResumePlayer;
    CGRect originalViewControllerFrame;
    CGAffineTransform fullScreenPlayerTransform;
    UIDeviceOrientation prevOrientation,deviceOrientation;
}

@synthesize  webView, player;
@synthesize delegate;

- (void)viewDidLoad
{
    NSLog( @"View Did Load Enter" );
    
    isFullScreen = NO;
    isPlaying = NO;
    isResumePlayer = NO;
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( pause ) name:@"videoPauseNotification" object:nil];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinchInOut:)];
    [self.view addGestureRecognizer:pinch];
    
    //    UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)
    
    NSLog( @"View Did Load Exit" );
}

-(void)didPinchInOut:(UIPinchGestureRecognizer *) recongizer {
    NSLog( @"didPinchInOut Enter" );
    
    if (isFullScreen && recongizer.scale < 1) {
        [self toggleFullscreen];
    } else if (!isFullScreen && recongizer.scale > 1) {
        [self toggleFullscreen];
    }
    
    NSLog( @"didPinchInOut Exit" );
}

-(void)viewWillAppear:(BOOL)animated{
    NSLog( @"viewWillAppear Enter" );
    
    CGRect playerViewFrame = CGRectMake( 0, 0, self.view.frame.size.width, self.view.frame.size.height );
    
    if ( !isFullScreen && !isResumePlayer ) {
        self.webView = [[PlayerControlsWebView alloc] initWithFrame: playerViewFrame];
        [self.webView setPlayerControlsWebViewDelegate: self];
        
        player = [[MPMoviePlayerController alloc] init];
        player.view.frame = playerViewFrame;
        
        // WebView initialize for supporting NativeComponent(html5 player view)
        [[self.webView scrollView] setScrollEnabled: NO];
        [[self.webView scrollView] setBounces: NO];
        [[self.webView scrollView] setBouncesZoom: NO];
        self.webView.opaque = NO;
        self.webView.backgroundColor = [UIColor clearColor];
        
        // Add NativeComponent(html5 player view) webView to player view
        [player.view addSubview: self.webView];
        [self.view addSubview: player.view];
        
        player.controlStyle = MPMovieControlStyleNone;
    }
    
    [super viewWillAppear:NO];
    
    NSLog( @"viewWillAppear Exit" );
}

- (void)viewDidDisappear:(BOOL)animated{
    isResumePlayer = YES;
    [super viewDidDisappear:animated];
}

- (void)setWebViewURL: (NSString *)iframeUrl{
    NSLog( @"setWebViewURL Enter" );
    
    iframeUrl = [iframeUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [self.webView loadRequest:[ NSURLRequest requestWithURL: [NSURL URLWithString:iframeUrl]]];
    
    NSLog(@"setWebViewURLExit");
}

- (void)play{
    NSLog( @"Play Player Enter" );
    
    if( !( player.playbackState == MPMoviePlaybackStatePlaying ) ) {
        [player prepareToPlay];
        [player play];
    }
    
    NSLog( @"Play Player Exit" );
}

- (void)UpdatePlayerLayout{
    NSLog( @"UpdatePlayerLayout Enter" );
    
    //TO:DO - find a better way to update player layout
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById( this.id ).doUpdateLayout();"];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:isFullScreen]
                                                         forKey:@"isFullScreen"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"toggleFullscreenNotification" object:self userInfo:dataDict];
    
    NSLog( @"UpdatePlayerLayout Exit" );
}

- (void)setOrientationTransform: (CGFloat) angle{
    NSLog( @"setOrientationTransform Enter" );
    
    if ( isFullScreen ) {
        fullScreenPlayerTransform = CGAffineTransformMakeRotation( ( angle * M_PI ) / 180.0f );
        fullScreenPlayerTransform = CGAffineTransformTranslate( fullScreenPlayerTransform, 0.0, 0.0);
        self.view.center = [[UIApplication sharedApplication] delegate].window.center;
        [self.view setTransform: fullScreenPlayerTransform];
        self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
        self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth |UIViewAutoresizingFlexibleHeight;
    }else{
        [self.view setTransform: CGAffineTransformIdentity];
    }
    
    
    NSLog( @"setOrientationTransform Exit" );
}

- (void)checkDeviceStatus{
    deviceOrientation = [[UIDevice currentDevice] orientation];
    
    if ([self isIpad]) {
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
            deviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
            [self setOrientationTransform: 90];
        }else{
            if ( deviceOrientation == UIDeviceOrientationLandscapeLeft ) {
                [self setOrientationTransform: 90];
            }else if( deviceOrientation == UIDeviceOrientationLandscapeRight ){
                [self setOrientationTransform: -90];
            }
        }
    }
}

- (void)checkOrientationStatus{
    NSLog( @"checkOrientationStatus Enter" );
    
    // Handle rotation issues when player is playing
    if ( isPlaying ) {
        //        if ( !isFullScreen ) {
        [self closeFullScreen];
        [self openFullScreen];
        //        }
        //        TO:DO e.g: player.goFullScreen(landscapeLeft); and!! player.goFullScreen(portrait);
        if ( isFullScreen ) {
            [self checkDeviceStatus];
        }
        
        if (![self isIpad] && (deviceOrientation == UIDeviceOrientationPortrait || deviceOrientation == UIDeviceOrientationPortraitUpsideDown) ) {
            [self closeFullScreen];
        }
    }else {
        [self closeFullScreen];
    }
    
    NSLog( @"checkOrientationStatus Exit" );
}

- (void)toggleFullscreen{
    NSLog( @"toggleFullscreen Enter" );
    
    if ( !isFullScreen ) {
        [self openFullScreen];
        [self checkDeviceStatus];
    } else{
        [self closeFullScreen];
    }
    
    NSLog( @"toggleFullscreen Exit" );
}

- (void)openFullScreen{
    NSLog( @"openFullScreen Enter" );
    
    //    if ( !isFullScreen ) {
    isFullScreen = YES;
    
    //        if ( CGRectIsEmpty( originalViewControllerFrame ) ) {
    //            originalViewControllerFrame = self.view.frame;
    //        }
    
    CGRect mainFrame;
    
    if ([self isIpad]) {
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
    
    if ( ![self isIOS7] ) {
        [UIApplication sharedApplication].statusBarHidden = YES;
    }
    
    [player.view setFrame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.webView setFrame: player.view.frame];
    [ self.view setTransform: fullScreenPlayerTransform ];
    [self triggerEventsJavaScript:@"enterfullscreen" WithValue:nil];
    
    //    }
    
    [self UpdatePlayerLayout];
    
    NSLog( @"openFullScreen Exit" );
}

- (void)closeFullScreen{
    NSLog( @"closeFullScreen Enter" );
    
    CGRect originalFrame = CGRectMake( 0, 0, originalViewControllerFrame.size.width, originalViewControllerFrame.size.height );
    isFullScreen = NO;
    
    [self.view setTransform: CGAffineTransformIdentity];
    self.view.frame = originalViewControllerFrame;
    self.player.view.frame = originalFrame;
    self.webView.frame = self.player.view.frame;
    
    if ( ![self isIOS7] ) {
       [UIApplication sharedApplication].statusBarHidden = NO;
    }
    
    [self triggerEventsJavaScript:@"exitfullscreen" WithValue:nil];
    
    [self UpdatePlayerLayout];
    
    NSLog( @"closeFullScreen Exit" );
}

- (void)pause{
    NSLog(@"Pause Player Enter");
    
    [player pause];
    
    NSLog(@"Pause Player Exit");
}

- (void)stop{
    NSLog(@"Stop Player Enter");
    
    [player stop];
    
    NSLog(@"Stop Player Exit");
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
    
    NSMutableDictionary *eventsDictionary = [[NSMutableDictionary alloc] init];
    [eventsDictionary setObject:MPMoviePlayerLoadStateDidChangeNotification forKey:@"triggerLoadPlabackEvents:"];
    [eventsDictionary setObject:MPMoviePlayerPlaybackDidFinishNotification forKey:@"triggerFinishPlabackEvents:"];
    [eventsDictionary setObject:MPMoviePlayerPlaybackStateDidChangeNotification forKey:@"triggerMoviePlabackEvents:"];
    [eventsDictionary setObject:MPMoviePlayerTimedMetadataUpdatedNotification forKey:@"metadataUpdate:"];
    [eventsDictionary setObject:MPMovieDurationAvailableNotification forKey:@"onMovieDurationAvailable:"];
    
    for (id functionName in eventsDictionary){
        id event = [eventsDictionary objectForKey:functionName];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(functionName) name:event object:player];
    }
    
    //  200 milliseconds is .2 seconds
    [NSTimer scheduledTimerWithTimeInterval:.2 target:self selector: @selector( sendCurrentTime: ) userInfo:nil repeats:YES];
    //  every second
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector: @selector( updatePlaybackProgressFromTimer: ) userInfo:nil repeats:YES];
    
    NSLog(@"Binding Events Exit");
}

- (void)triggerLoadPlabackEvents: (NSNotification *)note{
    NSLog(@"triggerLoadPlabackEvents Enter");
    
    NSString *loadStateName = [[NSString alloc]init];
    
    switch ( player.loadState ) {
        case MPMovieLoadStateUnknown:
            loadStateName = @"MPMovieLoadStateUnknown";
            NSLog(@"MPMovieLoadStateUnknown");
            break;
        case MPMovieLoadStatePlayable:
            loadStateName = @"canplay";
            NSLog(@"MPMovieLoadStatePlayable");
            break;
        case MPMovieLoadStatePlaythroughOK:
            loadStateName = @"MPMovieLoadStatePlaythroughOK";
            NSLog(@"MPMovieLoadStatePlaythroughOK");
            break;
        case MPMovieLoadStateStalled:
            loadStateName = @"stalled";
            NSLog(@"MPMovieLoadStateStalled");
            break;
        default:
            break;
    }
    
    [self triggerEventsJavaScript:loadStateName WithValue:nil];
    
    NSLog(@"triggerLoadPlabackEvents Exit");
}

- (void)triggerMoviePlabackEvents: (NSNotification *)note{
    NSLog(@"triggerMoviePlabackEvents Enter");
    
    NSString *playBackName = [[NSString alloc]init];
    
    
    if (isSeeking) {
        isSeeking = NO;
        playBackName = @"seeked";
        NSLog(@"MPMoviePlaybackStateStopSeeking");
        //called because there is another event that will be fired
        [self triggerEventsJavaScript:playBackName WithValue:nil];
    }
    
    switch ( player.playbackState ) {
        case MPMoviePlaybackStateStopped:
            isPlaying = NO;
            playBackName = @"stop";
            NSLog(@"MPMoviePlaybackStateStopped");
            break;
        case MPMoviePlaybackStatePlaying:
            isPlaying = YES;
            playBackName = @"play";
            NSLog(@"MPMoviePlaybackStatePlaying");
            break;
        case MPMoviePlaybackStatePaused:
            isPlaying = NO;
            playBackName = @"pause";
            NSLog(@"MPMoviePlaybackStatePaused");
            break;
        case MPMoviePlaybackStateInterrupted:
            playBackName = @"MPMoviePlaybackStateInterrupted";
            NSLog(@"MPMoviePlaybackStateInterrupted");
            break;
        case MPMoviePlaybackStateSeekingForward:
        case MPMoviePlaybackStateSeekingBackward:
            isSeeking = YES;
            playBackName = @"seeking";
            NSLog(@"MPMoviePlaybackStateSeeking");
            break;
        default:
            break;
    }
    
    [self triggerEventsJavaScript:playBackName WithValue:nil];
    
    NSLog(@"triggerMoviePlabackEvents Exit");
}

- (void)triggerFinishPlabackEvents:(NSNotification*)notification {
    NSLog(@"triggerFinishPlabackEvents Enter");
    
    NSString *finishPlayBackName = [[NSString alloc]init];
    NSNumber* reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    
    switch ([reason intValue]) {
        case MPMovieFinishReasonPlaybackEnded:
            finishPlayBackName = @"ended";
            NSLog(@"playbackFinished. Reason: Playback Ended");
            break;
        case MPMovieFinishReasonPlaybackError:
            finishPlayBackName = @"error";
            NSLog(@"playbackFinished. Reason: Playback Error");
            break;
        case MPMovieFinishReasonUserExited:
            finishPlayBackName = @"MPMovieFinishReasonUserExited";
            NSLog(@"playbackFinished. Reason: User Exited");
            break;
        default:
            break;
    }
    
    [self triggerEventsJavaScript:finishPlayBackName WithValue:nil];
    
    NSLog(@"triggerFinishPlabackEvents Exit");
}

- (void)triggerEventsJavaScript: (NSString *)eventName WithValue: (NSString *) eventValue{
    NSLog(@"triggerEventsJavaScript Enter");
    
    NSString* jsStringLog = [NSString stringWithFormat:@"trigger --> NativeBridge.videoPlayer.trigger('%@', '%@')", eventName, eventValue];
    NSLog(@"%@", jsStringLog);
    NSString* jsString = [NSString stringWithFormat:@"NativeBridge.videoPlayer.trigger('%@', '%@')", eventName,eventValue];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
    NSLog(@"triggerEventsJavaScript Exit");
}

- (void)setAttribute: (NSArray*)args{
    NSLog(@"setAttribute Enter");
    
    NSString *attributeName = [args objectAtIndex:0];
    Attribute attributeValue = [attributeName attributeNameEnumFromString];
    NSString *attributeVal;
    
    switch (attributeValue) {
        case src:
            attributeVal = [args objectAtIndex:1];
            [self setPlayerSource:attributeVal];
            break;
        case currentTime:
            attributeVal = [args objectAtIndex:1];
            if([player isPreparedToPlay]){
                [player setCurrentPlaybackTime:[attributeVal doubleValue]];
            }
            break;
        case visible:
            attributeVal = [args objectAtIndex:1];
            [self visible:attributeVal];
            break;
        case wvServerKey:
            attributeVal = [args objectAtIndex:1];
            [self visible:attributeVal];
            break;
            
        default:
            break;
    }
    
    NSLog(@"setAttribute Exit");
}

- (void)setPlayerSource: (NSString *)src{
    NSLog(@"setPlayerSource Enter");
    
    [player setContentURL:[NSURL URLWithString: src]];
    
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

- (void) onMovieDurationAvailable:(NSNotification *)notification {
    NSLog(@"onMovieDurationAvailable Enter");
    
    [self triggerEventsJavaScript:@"loadedmetadata" WithValue:[NSString stringWithFormat:@"%f",[player duration]]];
    [[NSNotificationCenter defaultCenter] removeObserver:player];
    
    NSLog(@"onMovieDurationAvailable Exit");
}

- (void) sendCurrentTime:(NSTimer *)timer {
    //    NSLog(@"sendCurrentTime Enter");
    
    if (([UIApplication sharedApplication].applicationState == UIApplicationStateActive) && (player.playbackState == MPMoviePlaybackStatePlaying)) {
        CGFloat currentTime = player.currentPlaybackTime;
        [self triggerEventsJavaScript:@"timeupdate" WithValue:[NSString stringWithFormat:@"%f", currentTime]];
    }
    
    //    NSLog(@"sendCurrentTime Exit");
}

- (void) updatePlaybackProgressFromTimer:(NSTimer *)timer {
    //    NSLog(@"updatePlaybackProgressFromTimer Enter");
    
    if (([UIApplication sharedApplication].applicationState == UIApplicationStateActive) && (player.playbackState == MPMoviePlaybackStatePlaying)) {
        CGFloat progress = player.playableDuration / player.duration;
        [self triggerEventsJavaScript:@"progress" WithValue:[NSString stringWithFormat:@"%f", progress]];
        //        NSLog(@"%@", [NSString stringWithFormat:@"progress:%f", progress]);
    }
    
    //    NSLog(@"updatePlaybackProgressFromTimer Exit");
}

- (void)stopAndRemovePlayer{
    NSLog(@"stopAndRemovePlayer Enter");
    
    [self visible:@"false"];
    [player stop];
    [player setContentURL:nil];
    [player.view removeFromSuperview];
    [self.webView removeFromSuperview];
    
    if(isFullScreen){
        isFullScreen = NO;
    }
    
    player = nil;
    self.webView = nil;
    
    NSLog(@"stopAndRemovePlayer Exit");
}

- (BOOL)isIpad{
    
    return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
}

- (BOOL)isIOS7{
    
    if ( floor( NSFoundationVersionNumber ) <= NSFoundationVersionNumber_iOS_6_1 ) {
        return NO;
    }
    
    return YES;
}

@end

@implementation NSString (EnumParser)
- (Attribute)attributeNameEnumFromString{
    NSLog(@"attributeNameEnumFromString Enter");
    
    NSDictionary *Attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInteger:src], @"src",
                                [NSNumber numberWithInteger:currentTime], @"currentTime",
                                nil
                                ];
    NSLog(@"attributeNameEnumFromString Exit");
    return (Attribute)[[Attributes objectForKey:self] intValue];
}
@end
