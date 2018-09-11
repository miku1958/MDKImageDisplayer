
Pod::Spec.new do |s|


  s.name         = "MDKImageCollection"
  s.version      = "1.1.6"
  s.summary      = "a image collection"

  s.description  = <<-DESC
  a image  collection
                   DESC

  s.homepage     = "https://github.com/miku1958/MDKImageCollection"


  s.license      = "Mozilla"


  s.author        = { "miku1958" => "v.v1958@qq.com" }

  s.platform     = :ios, "8.0"


  s.source       = { :git => "https://github.com/miku1958/MDKImageCollection.git", :tag => "#{s.version}" , :submodules => true}




  s.default_subspec = 'main'

  s.subspec 'main' do |ss|
    ss.source_files = "Class/main/**/*.{swift}"
  end


  s.subspec 'web' do |ss|
    ss.source_files = "Class/web/**/*.{swift}"
    ss.dependency 'MDKImageCollection/main'
  end

  s.requires_arc = true
  # s.static_framework = false
  s.prefix_header_file = false

  s.dependency "MDKTools/swift"

  s.swift_version = '4.0'

end

