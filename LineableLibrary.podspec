#
# Be sure to run `pod lib lint LineableLibrary.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "LineableLibrary"
  s.version          = "0.0.2"
  s.summary          = "Lineable is a smart wristband to prevent children from going missing."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
Detect active Lineables near the users.
If there are missing Lineables nearby, the data(The picture of a missing child, phone numbers of the parents and etc) will be provided and you can choose whether to notify the user or not. If you choose to notifty the user, the user can contribute to find the child.
                       DESC

  s.homepage         = "https://github.com/Lineable/iOS_LineableLibrary.git"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Doheny Yoon" => "berrymelon@lineable.net" }
  s.source           = { :git => "https://github.com/Lineable/iOS_LineableLibrary.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/lineable_inc'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'LineableLibrary' => ['Pod/Assets/*.png']
  }

  s.frameworks = 'UIKit'
end
