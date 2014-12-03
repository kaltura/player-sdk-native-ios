#import <UIKit/UIKit.h>

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
    nativeAction
} Attribute;

// JSCallbackReady Handler Block
typedef void (^JSCallbackReadyHandler)();

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

@property (nonatomic, copy, readonly) NSString *root;
@property (nonatomic, copy, readonly) NSString *wid;
@property (nonatomic, copy, readonly) NSString *uiConfId;
@property (nonatomic, copy, readonly) NSString *cacheSt;
@property (nonatomic, copy, readonly) NSString *entryId;
@property (nonatomic, copy, readonly) KPPlayerConfig *configFlags;
@property (nonatomic, copy, readonly) NSString *playerId;
//@property (nonatomic, assign, readonly) BOOL debug;
//@property (nonatomic, assign, readonly) BOOL forceMobileHTML5;
@property (nonatomic, copy, readonly) NSString *urid;

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

@end

