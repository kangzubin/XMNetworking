Pod::Spec.new do |s|
  s.name         = "XMNetworking"
  s.version      = "1.0.2"
  s.summary      = "A lightweight but powerful network library with simplified and expressive syntax based on AFNetworking."
  s.homepage     = "https://github.com/kangzubin/XMNetworking"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Zubin Kang" => "kangzubin@gmail.com" }

  s.platform     = :ios, "7.0"
  s.requires_arc = true

  s.source       = { :git => "https://github.com/kangzubin/XMNetworking.git", :tag => s.version, :submodules => true }

  s.source_files = "XMNetworking/XMNetworking.h"
  s.public_header_files = "XMNetworking/XMNetworking.h"

  s.subspec "Core" do |ss|
    ss.dependency "XMNetworking/Lib/AFNetworking-3.1.0"
    ss.source_files = "XMNetworking/Core/*.{h,m}"
    ss.public_header_files = "XMNetworking/Core/*.h"
  end

  s.subspec "Lib" do |ss|
    ss.subspec "AFNetworking-3.1.0" do |sss|
      sss.source_files = "XMNetworking/Lib/AFNetworking-3.1.0/*.{h,m}"
      sss.public_header_files = "XMNetworking/Lib/AFNetworking-3.1.0/*.h"
      sss.frameworks = "MobileCoreServices", "CoreGraphics", "Security", "SystemConfiguration"
    end
  end

end