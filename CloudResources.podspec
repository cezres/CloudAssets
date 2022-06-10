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
  spec.platform     = :ios, "12.0"
  spec.ios.deployment_target = "12.0"


  spec.source       = { :git => "https://github.com/cezres/CloudResources.git", :tag => "#{spec.version}" }


  spec.source_files  = "CloudAssets", "CloudAssets/**/*.{h,swift}"
  spec.public_header_files = "CloudAssets/**/*.h"


  
end
