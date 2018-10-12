Pod::Spec.new do |s|

s.platform = :ios
s.name             = "LDHTTPService"
s.version          = "1.0.0"
s.summary          = "This is internal library."

s.description      = <<-DESC
This is internal library. I will not add new functions on request.
DESC

s.homepage         = "https://github.com/lazar89nis/LDHTTPService"
s.license          = { :type => "MIT", :file => "LICENSE" }
s.author           = { "Lazar" => "lazar89nis@gmail.com" }
s.source           = { :git => "https://github.com/lazar89nis/LDHTTPService.git", :tag => "#{s.version}"}

s.ios.deployment_target = "9.0"
s.source_files = "LDHTTPService", "LDHTTPService/*", "LDHTTPService/**/*"

s.dependency 'Alamofire'
s.dependency 'AlamofireNetworkActivityIndicator'
s.dependency 'ReachabilitySwift'
s.dependency 'LDMainFramework'
s.dependency 'SDWebImage'
s.dependency 'SwiftyJSON'
s.dependency 'PKHUD'

end