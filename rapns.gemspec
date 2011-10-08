# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rapns/version"

Gem::Specification.new do |s|
  s.name        = "rapns"
  s.version     = Rapns::VERSION
  s.authors     = ["Ian Leitch"]
  s.email       = ["port001@gmail.com"]
  s.homepage    = "https://github.com/ileitch/rapns"
  s.summary     = %q{Easy to use library for Apple's Push Notification Service with Rails 3}
  s.description = %q{Easy to use library for Apple's Push Notification Service with Rails 3}

  s.files         = `git ls-files lib`.split("\n") + ["README.md"]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
