# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rpush/mongoid/version'

Gem::Specification.new do |spec|
  spec.name          = "rpush-mongoid"
  spec.version       = Rpush::Mongoid::VERSION
  spec.authors       = ["Ian Leitch"]
  spec.email         = ["port001@gmail.com"]
  spec.summary       = %q{Mongoid dependencies for Rpush.}
  spec.description   = %q{Mongoid dependencies for Rpush.}
  spec.homepage      = "https://github.com/rpush/rpush-mongoid"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency "mongoid", "~> 5.0.0"
  spec.add_runtime_dependency "mongoid-autoinc", "~> 5.0.0"
end
