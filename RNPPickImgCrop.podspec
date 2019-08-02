require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "RNPickImgCrop"
  s.version      = package['version']
  s.summary      = package['description']
  s.license      = package['license']

  s.authors      = package['author']
  s.homepage     = package['repository']['url']
  s.platform     = :ios, "9.0"
  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '10.0'

  s.source       = { :git => "https://github.com/gegeyang0124/react-native-pick-img-crop.git", :tag => "v" + package['version']  }
  s.source_files  = "ios/**/*.{h,m}"

  s.dependency 'React'
  s.dependency 'FLAnimatedImage', "~> 1.o"
end
