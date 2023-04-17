Pod::Spec.new do |s|
  s.name         = "XMNetworking"
  s.version      = "1.1.0"
  s.summary      = "A lightweight but powerful network library with simplified and expressive syntax based on AFNetworking."
  s.homepage     = "https://github.com/kangzubin/XMNetworking"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Zubin Kang" => "kangzubin@gmail.com" }

  s.platform     = :ios, "9.0"
  s.requires_arc = true

  s.source       = { :git => "https://github.com/kangzubin/XMNetworking.git", :tag => s.version, :submodules => true }

  s.source_files = "XMNetworking/*.{h,m}"
  s.public_header_files = "XMNetworking/*.h"
  
  s.dependency "AFNetworking", "~> 4.0"

end
