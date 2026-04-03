platform :ios, '15.0'
use_frameworks!

target 'GolfPS' do
    pod 'GoogleMaps'
    pod 'GoogleUtilities'

    pod 'SnapSDK', :subspecs => ['SCSDKLoginKit']
end


target 'GolfPSTests' do
  use_frameworks!
  
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
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
