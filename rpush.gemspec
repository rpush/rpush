# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "rpush/version"

Gem::Specification.new do |s|
  s.name        = "rpush"
  s.version     = Rpush::VERSION
  s.authors     = ["Ian Leitch"]
  s.email       = ["port001@gmail.com"]
  s.homepage    = "https://github.com/rpush/rpush"
  s.summary     = 'The push notification service for Ruby.'
  s.description = 'The push notification service for Ruby.'
  s.license     = 'MIT'

  s.files         = `git ls-files -- lib README.md CHANGELOG.md LICENSE`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}`.split("\n")
  s.executables   = `git ls-files -- bin`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'multi_json', '~> 1.0'
  s.add_runtime_dependency 'net-http-persistent', '< 3.0'
  s.add_runtime_dependency 'net-http2', '~> 0.14'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'thor', ['>= 0.18.1', '< 2.0']
  s.add_runtime_dependency 'railties'
  s.add_runtime_dependency 'ansi'

  if defined? JRUBY_VERSION
    s.platform = 'java'
    s.add_runtime_dependency "jruby-openssl"
    s.add_runtime_dependency "activerecord-jdbc-adapter"
  end
end
