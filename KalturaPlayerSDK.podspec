Pod::Spec.new do |s|
  s.name         = "KalturaPlayerSDK@MindSea"
  s.version      = "0.0.1"
  s.summary      = "The Kaltura player-sdk-native component enables embedding the kaltura player into native environments."
  s.homepage     = "https://github.com/MindSea/kaltura-player-sdk-native-ios"
  s.license      = { :type => 'COMMERCIAL', :text => 'COMMERCIAL' }
  s.author             = { "John Arnold" => "john@islandofdoom.com" }
  s.platform     = :ios, '6.0'
  s.source       = { :git => "git@github.com:MindSea/kaltura-player-sdk-native-ios.git", :tag => "0.0.1" }
  s.source_files  = 'PlayerSDK/PlayerSDK/KAL*.{h,m}'
  s.framework  = 'MediaPlayer'
  s.requires_arc = true
  s.dependency 'SBJson', '~> 4.0.0'
end
