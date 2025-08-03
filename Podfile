# Uncomment the next line to define a global platform for your project
# platform :ios, '15.0'

workspace 'CalendarWrap.xcworkspace'

target 'CalendarWrap' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for CalendarWrap
  pod 'MBProgressHUD'
  pod 'AlamofireImage'
  pod 'FBSDKCoreKit'
  pod 'FBSDKLoginKit'
  pod 'FBSDKShareKit'
  pod 'GoogleSignIn'
  pod 'GoogleAPIClientForREST/Calendar'
  
  post_install do |installer|
      installer.generated_projects.each do |project|
            project.targets.each do |target|
                target.build_configurations.each do |config|
                    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
                 end
            end
     end
  end

end
