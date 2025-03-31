platform :ios, '15.0'

target 'PushBetNotifApp' do
  use_frameworks!

  # Firebase SDKs
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
end

# 👇 This part adds the compiler flag to ALL Pods (like nanopb)
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['OTHER_CFLAGS'] ||= ['']
      config.build_settings['OTHER_CFLAGS'] << '-Wno-quoted-include-in-framework-header'
    end
  end

  # Clean DerivedData after every pod install
  system('rm -rf ~/Library/Developer/Xcode/DerivedData/*')
end
