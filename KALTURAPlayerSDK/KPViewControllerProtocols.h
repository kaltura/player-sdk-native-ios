#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

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
    // Player Error
    playerError,
    // DRM license uri
    licenseUri,

    nativeAction,
    doubleClickRequestAds,
    language,
    captions
} Attribute;

@protocol KPlayerDelegate;

@protocol KPlayer <NSObject>

@property (nonatomic, weak) id<KPlayerDelegate> delegate;
//@property (nonatomic, copy) NSURL *playerSource;
@property (nonatomic) NSTimeInterval currentPlaybackTime;
@property (nonatomic) NSTimeInterval duration;
@property (nonatomic) float volume NS_AVAILABLE(10_7, 7_0);
@property (nonatomic, getter=isMuted) BOOL mute NS_AVAILABLE(10_7, 7_0);
@property (nonatomic, readonly) BOOL isKPlayer;


- (instancetype)initWithParentView:(UIView *)parentView;
- (void)setPlayerSource:(NSURL *)playerSource;
- (NSURL *)playerSource;
- (void)play;
- (void)pause;
- (void)removePlayer;

@optional

- (void)enableTracks:(BOOL)isEnablingTracks;
+ (BOOL)isPlayableMIMEType:(NSString *)mimeType;
- (void)changeSubtitleLanguage:(NSString *)languageCode;
- (void)setSourceWithAsset:(AVURLAsset*)asset;
- (void)hidePlayer;

@end

@protocol KPlayerDelegate <NSObject>

- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event value:(NSString *)value;
- (void)player:(id<KPlayer>)currentPlayer eventName:(NSString *)event JSON:(NSString *)jsonString;
- (void)contentCompleted:(id<KPlayer>)currentPlayer;

@end

