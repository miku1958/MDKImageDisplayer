Pod::Spec.new do |s|


  s.name         = "MDKImageCollectionObjc"
  s.version      = "1.1.5"
  s.summary      = "a image collection objc version"

  s.description  = <<-DESC
  a image collection objc version
                   DESC

  s.homepage     = "https://github.com/miku1958/MDKImageCollection"


  s.license      = "Mozilla"


  s.author        = { "miku1958" => "v.v1958@qq.com" }

  s.platform     = :ios, "8.0"


  s.source       = { :git => "https://github.com/miku1958/MDKImageCollection.git", :tag => "#{s.version}" , :submodules => true}



  s.source_files = "Class/objc/*.h"
  s.dependency 'MDKImageCollection/main'

  s.requires_arc = true
  # s.static_framework = false
  s.prefix_header_file = false


  # s.swift_version = '4.0'

end
