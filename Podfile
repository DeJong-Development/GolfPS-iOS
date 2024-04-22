platform :ios, '14.0'
use_frameworks!

target 'GolfPS' do
    pod 'GoogleMaps'
    pod 'GoogleUtilities'
    
    pod 'Firebase/Core'
    pod 'Firebase/Auth'
    pod 'Firebase/Firestore'
    pod 'Firebase/Performance'
    pod 'Firebase/Analytics'
    pod 'Firebase/Crashlytics'

    pod 'SnapSDK', '~> 1.12'
end


target 'GolfPSTests' do
  use_frameworks!
  
  pod 'Firebase/Core'
  pod 'Firebase/Firestore'
  pod 'Firebase/Auth'
  pod 'GoogleUtilities'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
