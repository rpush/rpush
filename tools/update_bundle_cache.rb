#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'

FileUtils.rm_rf("vendor/cache")

RUBYS = ["2.0.0", "2.1.2", "rbx", "jruby"]
GEMFILES = ["Gemfile", "Gemfile.rails-4"]

RUBYS.each do |ruby|
    GEMFILES.each do |gemfile|
        cmd = "export BUNDLE_GEMFILE=#{gemfile}; rvm #{ruby} do bundle package --all --no-prune"
        puts cmd
        puts `#{cmd}`
    end
end
