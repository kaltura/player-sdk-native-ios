#import <UIKit/UIKit.h>

/// Player events constants
static NSString *KPlayerEventCanplay = @"canplay";
static NSString *KPlayerEventDurationChange = @"durationchange";
static NSString *KPlayerEventLoadedMetadata = @"loadedmetadata";
static NSString *KPlayerEventPlay = @"play";
static NSString *KPlayerEventPause = @"pause";
static NSString *KPlayerEventEnded = @"ended";
static NSString *KPlayerEventSeeking = @"seeking";
static NSString *KPlayerEventSeeked = @"seeked";
static NSString *KPlayerEventTimeupdate = @"timeupdate";
static NSString *KPlayerEventProgress = @"progress";
static NSString *KPlayerEventToggleFullScreen = @"toggleFullscreen";

/// Key names of the video request
static NSString *KPPlayerDatasourceWidKey = @"wid";
static NSString *KPPlayerDatasourceUiConfIdKey = @"uiconf_id";
static NSString *KPPlayerDatasourceCacheStKey = @"cache_st";
static NSString *KPPlayerDatasourceEntryId = @"entry_id";
static NSString *KPPlayerDatasourcePlayerIdKey = @"playerId";
static NSString *KPPlayerDatasourceUridKey = @"urid";
static NSString *KPPlayerDatasourceDebugKey = @"debug";
static NSString *KPPlayerDatasourceForceHtml5Key = @"forceMobileHTML5";

typedef enum{
    // Player Content Source Url
    src = 0,
    // Player Current time (Progress Bar)
    currentTime,
    // Player Visibility
    visible,
#if !(TARGET_IPHONE_SIMULATOR)
    // DRM WideVine Key
    wvServerKey,
#endif
    nativeAction,
    doubleClickRequestAds
} Attribute;


@protocol KPViewControllerDelegate <NSObject>

@required

@property (nonatomic, retain) id<KPViewControllerDelegate> kalPlayerViewControllerDelegate;
-(NSURL *)getInitialKIframeUrl;

@optional
- (void) kPlayerDidPlay;
- (void) kPlayerDidPause;
- (void) kPlayerDidStop;

@end

#import "KPPlayerConfig.h"
@protocol KPViewControllerDatasource <NSObject>
@optional
/// Address of the video server
@property (nonatomic, copy, readonly) NSString *serverAddress;

@property (nonatomic, copy, readonly) NSString *wid;
@property (nonatomic, copy, readonly) NSString *uiConfId;
@property (nonatomic, copy, readonly) NSString *cacheSt;
@property (nonatomic, copy, readonly) NSString *entryId;
@property (nonatomic, copy, readonly) KPPlayerConfig *configFlags;
@property (nonatomic, copy, readonly) NSString *playerId;
@property (nonatomic, copy, readonly) NSString *urid;
@property (nonatomic, copy, readonly) NSString *debug;
@property (nonatomic, copy, readonly) NSString *forceMobileHTML5;

@end




@protocol KalturaPlayer <NSObject>

@required

@property(readonly) UIView * view;
@property(readonly) int playbackState;
@property(readonly) int loadState;
@property(readonly) BOOL isPreparedToPlay;

@property (nonatomic, retain) id<KPViewControllerDelegate> delegate;
+ (id)alloc;

- (NSURL *)contentURL;
- (void)setContentURL:(NSURL *)cs;

- (double)currentPlaybackTime;
- (void)setCurrentPlaybackTime:(double)cs;

- (void)pause;
- (void)play;
- (void)stop;
- (int)playbackState;
- (BOOL)isPreparedToPlay;
- (double)playableDuration;
- (double)duration;
- (void)bindPlayerEvents;
- (void)sendCurrentTime:(NSTimer *)timer;
- (void)updatePlaybackProgressFromTimer:(NSTimer *)timer;

@optional
- (id)view;
- (int)controlStyle;
- (void)prepareToPlay;
- (int)loadState;

- (void)didLoad;
- (CGFloat) getCurrentTime;
- (instancetype) initWithFrame:(CGRect)frame forView:(UIView *)parentView;
- (void) copyParamsFromPlayer:(id<KalturaPlayer>) player;
- (void)initWV: (NSString *)src andKey: (NSString *)key;
- (void)setWideVideConfigurations;
- (void)setControlStyle:(int)cs;

- (void)showAdAtURL:(NSString *)adTagUrl updateAdEvents:(void(^)(NSDictionary *eventParams))updateBlock;

@end

