#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'

FileUtils.rm_rf("vendor/cache")

travis_yml = YAML.load(File.read(".travis.yml"))

travis_yml["rvm"].each do |ruby|
    travis_yml["gemfile"].each do |gemfile|
        cmd = "export BUNDLE_GEMFILE=#{gemfile}; rvm #{ruby} do bundle package --all --no-prune"
        puts cmd
        puts `#{cmd}`
    end
end
