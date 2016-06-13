

Pod::Spec.new do |s|



# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.name         = "player-sdk-native-ios"
s.version      = "2.3.5"
s.summary      = "The Kaltura player-sdk-native component enables embedding the kaltura player into native environments."

#s.description  = <<-DESC
#                 The Kaltura player-sdk-native component enables embedding the kaltura player into native environments.
#                 DESC
s.homepage     = "https://github.com/SachinAhujaWork/player-sdk-native-ios"




# ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.license      = { :type => 'AGPLv3', :text => 'AGPLv3' }



# ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.authors             = { "Eliza Sapir" => "eliza.sapir@gmail.com", "Nissim Pardo" => "nissim.pardo@kaltura.com" }



# ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.platform     = :ios, "8.0"



# ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.source       = { :git => 'https://github.com/SachinAhujaWork/player-sdk-native-ios.git' }
s.libraries      = 'stdc++', 'z', 'System', 'stdc++.6', 'xml2.2', 'c++', 'stdc++.6.0.9', 'xml2', 'WViPhoneAPI'
s.framework    = 'MediaPlayer', 'SystemConfiguration', 'QuartzCore', 'CoreFoundation', 'AVFoundation', 'AudioToolbox', 'CFNetwork', 'AdSupport', 'WebKit', 'MessageUI', 'Social', 'MediaAccessibility', 'Foundation', 'CoreGraphics', 'UIKit'

s.xcconfig = {'OTHER_LDFLAGS' => '-ObjC -all_load'}

s.dependency 'google-cast-sdk'
s.dependency 'GoogleAds-IMA-iOS-SDK-For-AdMob', '~> 3.0.beta.16'
s.requires_arc = true


# ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.source_files  = "**/*.{h,m}", "PlayerSDK/KALTURAPlayerSDK/**/*.{h,m}"
s.vendored_library = 'libWViPhoneAPI.a'
s.resource_bundle = { 'KALTURAPlayerSDKResources' => 'KALTURAPlayerSDK/*.{xib,plist}' }
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

s.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
end
