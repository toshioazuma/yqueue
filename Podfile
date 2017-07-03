platform :ios, '8.0'
use_frameworks!

target 'YQueue-Merchant' do
  pod 'ReactiveCocoa', :git => 'https://github.com/ReactiveCocoa/ReactiveCocoa.git'
  pod 'AWSCognito'
  pod 'AWSCognitoIdentityProvider'
  pod 'AWSDynamoDB'
  pod 'AWSS3'
  pod 'AWSSNS'
  pod 'AWSSES'
  pod 'MBProgressHUD'
  pod 'SideMenu'
  pod 'XLPagerTabStrip'
  pod 'FBSDKCoreKit'
  pod 'FBSDKLoginKit'
  pod 'FBSDKShareKit'
  pod 'MGSwipeTableCell'
  pod 'Cosmos', '~> 7.0'
end

target 'YQueue' do
  pod 'ReactiveCocoa', :git => 'https://github.com/ReactiveCocoa/ReactiveCocoa.git'
  pod 'AWSCognito'
  pod 'AWSCognitoIdentityProvider'
  pod 'AWSDynamoDB'
  pod 'AWSS3'
  pod 'AWSSNS'
  pod 'AWSSES'
  pod 'MBProgressHUD'
  pod 'SideMenu'
  pod 'XLPagerTabStrip'
  pod 'FBSDKCoreKit'
  pod 'FBSDKLoginKit'
  pod 'FBSDKShareKit'
  pod 'MGSwipeTableCell'
  pod 'Cosmos', '~> 7.0'
end

post_install do |installer|
  installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
    configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
  end

  installer.pods_project.targets.each do |target|
    puts "TARGET #{target.name}"
    if target.name == "ReactiveCocoa" || "ReactiveSwift"
        target.build_configurations.each do |configuration|
       	  configuration.build_settings['SWIFT_VERSION'] = '3.0'
        end
      end
    end
end
