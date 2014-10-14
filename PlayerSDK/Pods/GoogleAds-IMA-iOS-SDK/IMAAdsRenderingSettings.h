//
//  IMAAdsRenderingSettings.h
//  GoogleIMA3
//
//  Copyright (c) 2013 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/// The default value of |bitrate property|, causes the effective bitrate to
/// be automatically selected.
extern const int kIMAAutodetectBitrate;

/// Signals that a internal or external web browser has been opened or closed.
/// For an external browser (Mobile Safari), the delegate is only notified
/// before opening.
@protocol IMAWebOpenerDelegate<NSObject>

@optional

/// Called when Safari is about to be opened.
- (void)willOpenExternalBrowser;
/// Called before in-app browser opens.
- (void)willOpenInAppBrowser;
/// Called when in-app browser finishes closing.
- (void)didCloseInAppBrowser;
/// Called when the in app browser is shown on the screen.
- (void)didOpenInAppBrowser;
/// Called when in-app browser is about to close.
- (void)willCloseInAppBrowser;

@end

/// Set of properties that influence how ads are rendered.
@interface IMAAdsRenderingSettings : NSObject

/// If specified, the SDK will prioritize the media with MIME type on the list.
/// List of strings specifying the MIME types. When nil or empty, the SDK will
/// use it's default list of MIME types supported on iOS.
/// Example: @[ @"video/mp4", @"application/x-mpegURL" ]
/// The property is an empty array by default.
@property(nonatomic, strong) NSArray *mimeTypes;

/// Maximum recommended bitrate. The value is in kbit/s.
/// SDK will pick media with bitrate below the specified max, or the closest
/// bitrate if there is no media with smaller bitrate found.
/// Default value, |kIMAAutodetectBitrate|, means the bitrate will be selected
/// by the SDK, using the currently detected network speed (cellular or Wi-Fi).
@property(nonatomic, assign) int bitrate;

/// Specifies the optional UIViewController that will be used to present an
/// in-app browser.
/// When nil, tapping the video ad "Learn More" button or companion ads
/// will result in opening Safari browser. If provided, in-app browser will
/// be used, allowing the user to stay in the app and return easily.
@property(nonatomic, strong) UIViewController *webOpenerPresentingController;

/// Delegate to be notified when in-app or external browser opens/closes.
@property(nonatomic, weak) id<IMAWebOpenerDelegate> webOpenerDelegate;

@end
