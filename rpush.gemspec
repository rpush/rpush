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
  s.metadata    = {
    "bug_tracker_uri" => "https://github.com/rpush/rpush/issues",
    "changelog_uri" => "https://github.com/rpush/rpush/blob/master/CHANGELOG.md",
    "source_code_uri" => "https://github.com/rpush/rpush",
    "rubygems_mfa_required" => "true"
  }

  s.files         = `git ls-files -- lib README.md CHANGELOG.md LICENSE`.split("\n")
  s.executables   = `git ls-files -- bin`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 2.7.0'

  s.post_install_message = <<~POST_INSTALL_MESSAGE
    When upgrading Rpush, don't forget to run `bundle exec rpush init` to get all the latest migrations.

    For details on this specific release, refer to the CHANGELOG.md file.
    https://github.com/rpush/rpush/blob/master/CHANGELOG.md
  POST_INSTALL_MESSAGE

  s.add_dependency 'multi_json', '~> 1.0'
  s.add_dependency 'net-http-persistent'
  s.add_dependency 'net-http2', '~> 0.18', '>= 0.18.3'
  s.add_dependency 'jwt', '>= 1.5.6'
  s.add_dependency 'activesupport', '>= 5.2', '< 7.1.0'
  s.add_dependency 'thor', ['>= 0.18.1', '< 2.0']
  s.add_dependency 'railties'
  s.add_dependency 'rainbow'
  s.add_dependency 'web-push'
  s.add_dependency 'googleauth'
end
