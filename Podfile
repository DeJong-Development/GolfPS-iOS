platform :ios, '14.0'
use_frameworks!

target 'GolfPS' do
    pod 'BoringSSL-GRPC', '0.0.24'
    pod 'GoogleMaps'
    pod 'Google-Maps-iOS-Utils'
    pod 'GooglePlaces'
    pod 'Firebase/Auth'
    pod 'Firebase/Firestore'
    pod 'Firebase/Performance'
    pod 'Firebase/Core'
    pod 'Firebase/Analytics'
    pod 'Firebase/Crashlytics', '10.22.0'
    pod 'GoogleUtilities'

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
