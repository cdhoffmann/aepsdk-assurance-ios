# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

use_frameworks!
workspace 'AEPAssurance'
project 'AEPAssurance.xcodeproj'

pod 'SwiftLint', '0.52.0'

target 'AEPAssurance' do
  pod 'AEPCore', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPServices', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPRulesEngine', :path => '~/code/MobileSDK/Forks/aepsdk-rulesengine-ios/'
end

target 'UnitTests' do
  pod 'AEPCore', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPServices', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPRulesEngine', :path => '~/code/MobileSDK/Forks/aepsdk-rulesengine-ios/'
end

target 'TestApp' do
  pod 'AEPCore', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPServices', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPLifecycle', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPIdentity', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPSignal', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'staging'
  pod 'AEPEdgeIdentity'
  pod 'AEPUserProfile', :git => 'https://github.com/adobe/aepsdk-userprofile-ios.git', :branch => 'staging'
  pod 'AEPTarget', :git => 'https://github.com/adobe/aepsdk-target-ios.git', :branch => 'staging'
  pod 'AEPAnalytics'
  pod 'AEPPlaces', :git => 'https://github.com/adobe/aepsdk-places-ios.git', :branch => 'staging'
  pod 'AEPMessaging', :git => 'https://github.com/adobe/aepsdk-messaging-ios.git', :branch => 'staging'
end

target 'TestAppObjC' do
  pod 'AEPCore', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPServices', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPLifecycle', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPIdentity', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPSignal', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent', :git => 'https://github.com/adobe/aepsdk-edgeconsent-ios.git', :branch => 'staging'
  pod 'AEPEdgeIdentity'
  pod 'AEPUserProfile', :git => 'https://github.com/adobe/aepsdk-userprofile-ios.git', :branch => 'staging'
  pod 'AEPTarget', :git => 'https://github.com/adobe/aepsdk-target-ios.git', :branch => 'staging'
  pod 'AEPAnalytics'
  pod 'AEPPlaces', :git => 'https://github.com/adobe/aepsdk-places-ios.git', :branch => 'staging'
end

target 'TestAppVisionPro' do
  pod 'AEPCore', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPServices', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPLifecycle', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPIdentity', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPSignal', :path => '~/code/MobileSDK/Forks/aepsdk-core-ios/'
  pod 'AEPEdge'
  pod 'AEPEdgeIdentity'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Activate VisionOS support for all Pods
      config.build_settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator xros xrsimulator' # Includes VisionOS (xros) and its simulator (xrsimulator)
      config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2,7' # Incorporate device family '7' for VisionOS
    end
  end
end
