Pod::Spec.new do |spec|

  spec.name         = "CloudResources"
  spec.version      = "0.1.0"
  spec.summary      = "CloudResources."


  spec.description  = <<-DESC
  CloudResources
                   DESC

  spec.homepage     = "https://github.com/cezres/CloudResources"
  spec.license      = "MIT"


  spec.author             = { "cezres" => "cezres@163.com" }


  spec.swift_version = '5'
  spec.module_name = 'CloudResources'
  spec.platform     = :ios, "13.0"
  spec.ios.deployment_target = "13.0"


  spec.source       = { :git => "https://github.com/cezres/CloudResources.git", :tag => "#{spec.version}" }


  spec.default_subspecs = 'Core'

  spec.subspec 'Foundation' do |ss|
    ss.source_files = 'CloudResourcesFoundation/**/*.swift'
    ss.exclude_files = 'CloudResourcesFoundation/Package.swift'
  end


  spec.subspec 'Core' do |ss|
    ss.source_files  = "CloudResources", "CloudResources/**/*.{h,swift}"
    ss.public_header_files = "CloudResources/**/*.h"
    ss.dependency 'CloudResources/Foundation'
  end
  
end
