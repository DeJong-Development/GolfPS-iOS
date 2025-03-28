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

    pod 'SnapSDK', :subspecs => ['SCSDKLoginKit', 'SCSDKCreativeKit']
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
    if target.name == 'BoringSSL-GRPC'
      target.source_build_phase.files.each do |file|
        if file.settings && file.settings['COMPILER_FLAGS']
          flags = file.settings['COMPILER_FLAGS'].split
          flags.reject! { |flag| flag == '-GCC_WARN_INHIBIT_ALL_WARNINGS' }
          file.settings['COMPILER_FLAGS'] = flags.join(' ')
        end
      end
    end
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
