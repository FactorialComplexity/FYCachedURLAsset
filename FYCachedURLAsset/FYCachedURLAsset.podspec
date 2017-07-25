#
# Be sure to run `pod lib lint FYCachedURLAsset.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FYCachedURLAsset'
  s.version          = '0.1.0'
  s.summary          = 'Provides local cache layer for remote audio and video stream  files'

# This description is used to generate tags and improve search results.
  s.description      = <<-DESC
Handles simultaneous streaming and caching of audio and video files in a way that each byte is downloaded only once.
                       DESC

  s.homepage         = 'https://github.com/FactorialComplexity/FYCachedURLAsset'
  s.screenshots     = 'https://github.com/FactorialComplexity/FYCachedURLAsset/raw/master/FYCachedUrlAsset.png'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Vitaliy Ivanov' => 'wicharek@gmail.com', 'Viktor Naryshkin' => 'viktor.naryshkin@factorialcomplexity.com' }
  s.source           = { :git => 'https://github.com/FactorialComplexity/FYCachedURLAsset.git', :tag => s.version.to_s }
  # s.social_media_url = 'http://'

  s.ios.deployment_target = '8.0'

  s.source_files = 'FYCachedURLAsset/Classes/*'
  
  # s.resource_bundles = {
  #   'FYCachedURLAsset' => ['FYCachedURLAsset/Assets/*.png']
  # }

  s.public_header_files = 'Pod/Classes/*.h'
  s.frameworks = 'Foundation', 'UIKit', 'AVFoundation'
end
