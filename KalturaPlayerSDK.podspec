

Pod::Spec.new do |s|



# ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.name         = "KalturaPlayerSDK"
s.version      = "2.0.5"
s.summary      = "The Kaltura player-sdk-native component enables embedding the kaltura player into native environments."

#s.description  = <<-DESC
#                 The Kaltura player-sdk-native component enables embedding the kaltura player into native environments.
#                 DESC
s.homepage     = "https://github.com/kaltura/player-sdk-native-ios"




# ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.license      = { :type => 'AGPLv3', :text => 'AGPLv3' }



# ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.authors             = { "Eliza Sapir" => "eliza.sapir@gmail.com", "Nissim Pardo" => "nissim.pardo@kaltura.com" }



# ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.platform     = :ios, "8.0"



# ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
s.source       = { :git => 'https://github.com/kaltura/player-sdk-native-ios.git', :tag => 'v' + s.version.to_s }
s.libraries      = 'stdc++', 'z', 'System', 'stdc++.6', 'xml2.2', 'c++', 'stdc++.6.0.9', 'xml2', 'WViPhoneAPI'
s.framework    = 'MediaPlayer', 'SystemConfiguration', 'QuartzCore', 'CoreFoundation', 'AVFoundation', 'AudioToolbox', 'CFNetwork', 'AdSupport', 'WebKit', 'MessageUI', 'Social', 'MediaAccessibility', 'Foundation', 'CoreGraphics', 'UIKit'

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
