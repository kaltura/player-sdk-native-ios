[![Build Status](https://travis-ci.org/kaltura/player-sdk-native-ios.svg?branch=master)](https://travis-ci.org/kaltura/player-sdk-native-ios)
[![Version](https://img.shields.io/cocoapods/v/KalturaPlayerSDK.svg?style=flat)](http://cocoadocs.org/docsets/KalturaPlayerSDK)
[![License](https://img.shields.io/cocoapods/l/KalturaPlayerSDK.svg?style=flat)](http://cocoadocs.org/docsets/KalturaPlayerSDK)
[![Platform](https://img.shields.io/cocoapods/p/KalturaPlayerSDK.svg?style=flat)](http://cocoadocs.org/docsets/KalturaPlayerSDK)

Player SDK Native iOS
=================

**Note**: The Kaltura native player component is in beta. If you are a Kaltura customer, please contact your Kaltura Customer Success Manager to help facilitate use of this component. 

The Kaltura player-sdk-native component enables embedding the [kaltura player](http://player.kaltura.com) into native environments. This enables the full HTML5 player platform, without limitations of HTML5 video tag API in iOS platforms. Currently, for iOS this enables: 
* Inline playback with HTML controls ( disable controls during ads etc. ) 
* Widevine DRM support
* AutoPlay 
* Volume Control
* Full [player.kaltura.com](http://player.kaltura.com) feature set for themes and plugins
* DFP IMA SDK

For a full list of native embed advantages, see the native controls table within the [player toolkit basic usage guide](http://knowledge.kaltura.com/kaltura-player-v2-toolkit-theme-skin-guide). 

The Kaltura player-sdk-native component can be embedded into both native apps, and hybrid native apps (via standard dynamic embed syntax) 


Future support will include: 
* PlayReady DRM
* Multiple stream playback
* Offline viewing

## Table of Contents

* [**Architecture Overview**](#architecture-overview)  
* [**Getting Started**](#getting-started)
* [**Linking GoogleAds**](#linking-googleads)
* [**Linking GoogleCast**](#linking-googlecast)
* [**Using Kaltura player**](#using-kaltura-player)  
* [**License and Copyright Information**](#license-and-copyright-information)  

Architecture Overview
=====
![alt text](http://html5video.org/presentations/HTML5PartDeux.FOSDEM.2014/koverview.jpg "Architecture Overview")


Getting Started
======

**KalturaPlayerSDK** can be added to any project (big or small) in a matter of minutes (maybe even seconds if you're super speedy). Cocoapods is fully supported.

##SDK Cocoapods Installation :

The easiest way to install KalturaPlayerSDK is to use <a href="http://cocoapods.org/" target="_blank">CocoaPods</a>. To do so, simply add the following line to your `Podfile`:
	<pre><code>pod 'KalturaPlayerSDK'</code></pre>

##SDK Traditional Installation :

```
git clone https://github.com/kaltura/player-sdk-native-ios.git
```
###Add the static library's .xcodeproj to the app's project

1. Find the _**`KALTURAPlayerSDK.xcodeproj`**_ from the subproject folder in _**`Finder`**_, and drag it into Xcode’s Navigator tree. Alternatively, add it with Xcode’s _**`Add Files`**_ File menu item.

![alt text](http://knowledge.kaltura.com/sites/default/files/styles/large/public/add_files.png)

Make sure to add the _**`KALTURAPlayerSDK.xcodeproj`**_ file only, **not the entire directory.** You can’t have the same project open in two different Xcode windows.If you find that you’re unable to navigate around the library project, check that you don’t have it open in another Xcode window. After you’ve added the subproject, it should appear below the main project in the Xcode’s Navigator tree:

![alt text](http://knowledge.kaltura.com/sites/default/files/styles/large/public/xcodetree.png)

###Configure the app target to build the static library target.
3. You will need to get the main project to build and link to the KALTURAPlayerSDK library.
4. In the main project app’s target settings, find the _**`Build Phases`**_ section. This is where you’ll configure the _**`KALTURAPlayerSDK`**_ target to automatically build and link to the _**`KALTURAPlayerSDK`**_ library. 
5. After you’ve found the _**`Build Phases`**_ section, open the _**`Target Dependencies`**_ block and click the **`+`** button. In the hierarchy presented to you, the _**`KALTURAPlayerSDK`**_ target from the _**`KALTURAPlayerSDK`**_ project should be listed. Select it and click _**`Add`**_.![alt text](http://knowledge.kaltura.com/sites/default/files/styles/large/public/addDependencie.jpg)

###Configure the app target to link to the static library target.

1. You will need to set the app to link to the library when it’s built - just like you would a system framework you would want to use. Open the _**`Link Binary With Libraries`**_ section located a bit below the _**`Target Dependencies`**_ section, and click **`+`** in there too. At the top of the list there should be the _**`libKALTURAPlayerSDK.a`**_ static library that the main project target produces. Choose it and click _**`Add`**_.
![alt text](http://knowledge.kaltura.com/sites/default/files/styles/large/public/linkToSDK.jpg)
2. Because we are using Objective-C, we have to add a couple of linker flags to the main project app’s target to ensure that ObjC static libraries like ours are linked correctly. In the main project target’s _**`Build Settings`**_ find the _**`Other Linker Flags`**_ line, and add _**`-ObjC`**_.![alt text](http://knowledge.kaltura.com/sites/default/files/styles/large/public/addingObjC_flag.jpg)

Linking GoogleCast
======
###Cocoapods support
If you are using cocoapods please attach the following to your pod file:
```
	pod 'google-cast-sdk'
```
###Linking to “GoogleCast.framework”
1.	Go to Target -> _**`Build Phases`**_ -> _**`Link Binary with Library`**_, click the **`+`** and _**`Add Other...`**_
2.	Go to PlayerSDK folder and you will see that it contains _**`GoogleCast.framework`**_ choose it and click -**`Open`**_. ![alt text](http://knowledge.kaltura.com/sites/default/files/styles/large/public/linkToChromecast.jpg)

Linking GoogleAds
======
###Cocoapods support
If you are using cocoapods please attach the following to your pod file:
```
   	pod 'Google-Mobile-Ads-SDK'
    pod 'google-cast-sdk'
    pod 'GoogleAds-IMA-iOS-SDK-For-AdMob', '~> 3.0.beta.16'
```

###Linking to GoogleInteractiveMediaAds SDK
1. If you use ads you will have to download **`GoogleMobileAds`** from: [Admob](https://developers.google.com/admob/ios/download) and add it to your project
2. In addition to the **`GoogleMobileAds`** you should download **`GoogleInteractiveMediaAds`** from: [IMA SDK](https://developers.google.com/interactive-media-ads/docs/sdks/ios/download), if you are going to use **Admob** in addition to the **`IMA SDK`** you should add **GoogleInteractiveMediaAds-GoogleIMA3ForAdMob** to your project and if you are going to use only **`IMA SDK`** you should add **GoogleInteractiveMediaAds-GoogleIMA3** to your project.
3. Required frameworks for **`GoogleMobileAds`**:
	1. StoreKit.framework
	2. EventKit.framework
	3. EventKitUI.framework
	4. CoreTelephony.framework
	5. MessageUI.framework

###Required Frameworks 
	•	SystemConfiguration
	•	QuartzCore
	•	CoreMedia
	•	AVFoundation
	•	AudioToolbox
	•	AdSupport
	•	WebKit
	•	Social
	•	MediaAccessibility
	•	libSystem.dylib
	•	libz.dylib
	•	libstdc++.dylib
	•	libstdc++.6.dylib
	•	libstdc++.6.0.9.dylib
	•	libxml2.dylib
	•	libxml2.2.dylib
	•	libc++.dylib

###Adding Resources Bundle

1. Choose the app target from the Targets  section.  
2. Go to the _**`Products`**_ folder and drag the _**`KALTURAPlayerSDK.bundle`**_ to _**`Copy Bundle Resources`**_ section.![alt text](http://knowledge.kaltura.com/sites/default/files/styles/large/public/Bundle.png)

** If you click build now, you will see that the PlayerSDK library is built before the main project app, and they are linked together.**


Using Kaltura player
=====

###To Import KPViewController to main project

```
#import <KALTURAPlayerSDK/KPViewController.h>
```
###Create KPViewController instance:
```
@property (retain, nonatomic) KPViewController *player;
```

###To Initialize PlayerViewController for Fullscreen:
```
- (KPViewController *)player {
    if (!_player) {
        // Account Params
        KPPlayerConfig *config = [[KPPlayerConfig alloc] initWithDomain:@"http://cdnapi.kaltura.com"
                                           uiConfID:@"26698911"
                                           partnerId:@"1831271"];
    
    
    // Video Entry
    config.entryId = @"1_o426d3i4";
        
        // Setting this property will cache the html pages in the limit size
        config.cacheSize = 0.8;
        _player = [[KPViewController alloc] initWithConfiguration:config];
    }
    return _player;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
 
    [self presentViewController:self.player animated:YES completion:nil];
}

```
###To Initialize PlayerViewController for Inline
```
- (KPViewController *)player {
    if (!_player) {
        // Account Params
        KPPlayerConfig *config = [[KPPlayerConfig alloc] initWithDomain:@"http://cdnapi.kaltura.com"
                                           uiConfID:@"26698911"
                                           partnerId:@"1831271"];
        
        
        // Video Entry
        config.entryId = @"1_o426d3i4";
        
        // Setting this property will cache the html pages in the limit size
        config.cacheSize = 0.8;
        _player = [[KPViewController alloc] initWithConfiguration:config];
    }
    return _player;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.player.view.frame = (CGRect){0, 0, 320, 180};
    [self.player loadPlayerIntoViewController:self];
    [self.view addSubview:_player.view];
}


```

License and Copyright Information
===

All player-sdk-native-ios code is released under the AGPLv3 unless a different license for a particular library is specified in the applicable library path
