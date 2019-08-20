package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name             = "RNPickImgCrop"
  s.summary          = package["description"]
  s.version          = package['version']
  s.requires_arc = true
  s.license      = package['license']
  s.homepage     = package['repository']['url']
  s.authors      = package['author']
  s.source       = { :git => "https://github.com/gegeyang0124/react-native-pick-img-crop.git", :tag => "v" + package['version']  }
  s.source_files  = "ios/**/*.{h,m}"
  s.resource_bundles = {
  "RNPickImgCrop" => [
           "ios/XGAssetPickerController/*.{lproj,storyboard,xib}",
           "ios/ZYImageCropper/*.{lproj,storyboard,xib}"
     ]
  }
  s.resources = "ios/**/*.{bundle}"
  s.platform     = :ios, "8.0"
  s.dependency 'React'
  s.dependency 'FLAnimatedImage', "~> 1.0"
end

