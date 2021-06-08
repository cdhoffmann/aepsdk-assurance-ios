# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

use_frameworks!
workspace 'AEPAssurance'
project 'AEPAssurance.xcodeproj'

target 'AEPAssurance' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
end

target 'UnitTests' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
end

target 'TestApp' do
  pod 'AEPCore', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
  pod 'AEPServices', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
  pod 'AEPLifecycle', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
  pod 'AEPIdentity', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
  pod 'AEPSignal', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :branch => 'main'
  pod 'AEPEdge'
  pod 'AEPEdgeConsent'
  pod 'AEPEdgeIdentity'
  pod 'AEPUserProfile'
  pod 'AEPTarget'
  pod 'AEPAnalytics'
  pod 'AEPPlaces'
end
