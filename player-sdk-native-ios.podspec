

Pod::Spec.new do |s|



# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.name         = "player-sdk-native-ios"
s.version      = "1.1"
s.summary      = "The Kaltura player-sdk-native component enables embedding the kaltura player into native environments."

#s.description  = <<-DESC
#                 The Kaltura player-sdk-native component enables embedding the kaltura player into native environments.
#                 DESC
s.homepage     = "https://github.com/kaltura/player-sdk-native-ios"




# ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.license      = { :type => 'COMMERCIAL', :text => 'COMMERCIAL' }



# ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.author             = { "Nissim Pardo" => "nissim.pardo@kaltura.com" }



# ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.platform     = :ios, "6.0"



# ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.source       = { :git => 'https://github.com/kaltura/player-sdk-native-ios.git', :tag => 'v1.1' }
s.library      = 'stdc++', 'z', 'System', 'stdc++.6', 'xml2.2', 'c++', 'stdc++.6.0.9', 'xml2'
s.framework    = 'MediaPlayer', 'GoogleCast', 'SystemConfiguration', 'QuartzCore', 'CoreFoundation', 'AVFoundation', 'AudioToolbox', 'CFNetwork', 'AdSupport', 'WebKit', 'MessageUI', 'Social', 'MediaAccessibility', 'Foundation', 'CoreGraphics', 'UIKit'

s.xcconfig = {'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/google-cast-sdk/GoogleCastFramework-2.3.0-Release',
                    'OTHER_LDFLAGS' => '-ObjC -all_load'}

s.dependency 'google-cast-sdk', '2.3.0'
s.dependency 'GoogleAds-IMA-iOS-SDK', '3.0.beta.11'
s.requires_arc = true


# ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.source_files  = "PlayerSDK/**/*.{h,m}", "PlayerSDK/PlayerSDK/**/*.{h,m}"
s.vendored_library = 'PlayerSDK/libWViPhoneAPI.a'
#s.exclude_files = "Classes/Exclude"

# ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
#
#  A list of resources included with the Pod. These are copied into the
#  target bundle with a build phase script. Anything else will be cleaned.
#  You can preserve files from being cleaned, please don't preserve
#  non-essential files like tests, examples and documentation.
#

# s.resource  = "icon.png"
# s.resources = "Resources/*.png"

# s.preserve_paths = "FilesToSave", "MoreFilesToSave"


end
