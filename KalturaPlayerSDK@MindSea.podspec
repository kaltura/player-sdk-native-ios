Pod::Spec.new do |s|
  s.name         = "KalturaPlayerSDK@MindSea"
  s.version      = "0.0.4-ms"
  s.summary      = "The Kaltura player-sdk-native component enables embedding the kaltura player into native environments."
  s.homepage     = "https://github.com/MindSea/kaltura-player-sdk-native-ios"
  s.license      = { :type => 'COMMERCIAL', :text => 'COMMERCIAL' }
  s.author             = { "Mike Burke" => "mike.burke@mindsea.com" }
  s.platform     = :ios, '6.0'
  s.source       = { :git => "https://github.com/MindSea/kaltura-player-sdk-native-ios.git", :tag => "0.0.4-ms" }
  s.source_files  = 'PlayerSDK/PlayerSDK/KAL*.{h,m}', 'PlayerSDK/KAL*.{h,m}'
  s.framework  = 'MediaPlayer'
  s.requires_arc = true
end
