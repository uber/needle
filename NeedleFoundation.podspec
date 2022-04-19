Pod::Spec.new do |s|
  s.name             = 'NeedleFoundation'
  s.version          = '0.18.1'
  s.summary          = 'Compile-time safe Swift dependency injection framework with real code.'
  s.description      = 'Needle is a dependency injection (DI) system for Swift. Unlike other DI frameworks, such as Cleanse, Swinject, Needle encourages hierarchical DI structure and utilizes code generation to ensure compile-time safety. This allows us to develop our apps and make changes with confidence. If it compiles, it works. In this aspect, Needle is more similar to Android Dagger.'

  s.homepage         = 'https://github.com/uber/needle'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.author           = { 'Yi Wang' => 'yiw@uber.com' }

  s.source           = { :git => 'https://github.com/uber/needle.git', :tag => "v" + s.version.to_s }
  s.source_files     = 'Sources/**/*.swift'
  s.ios.deployment_target = '9.0'
  s.swift_version    = '4.2'
end
