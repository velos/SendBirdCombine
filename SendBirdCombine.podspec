#
# Be sure to run `pod lib lint SendBirdCombine.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SendBirdCombine'
  s.version          = '1.0.0'
  s.summary          = 'Provides Combine extensions for the SendBird chat service SDK'

  s.description      = <<-DESC
                        This pod provides Combine extensions for the SendBird chat service SDK
                       DESC

  s.homepage         = 'https://github.com/velos/sendbird-combine'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'David Rajan' => 'david@velosmobile.com' }
  s.source           = { :git => 'https://github.com/velos/sendbird-combine.git', :tag => s.version.to_s }

  s.platform = :ios, '13.0'
  s.ios.deployment_target = '13.0'

  s.source_files = 'SendBirdCombine/Classes/**/*'

  s.frameworks = 'Combine'
  s.dependency 'SendBirdSDK', '~> 3.0'
  s.dependency 'SendBirdSDK'
end
