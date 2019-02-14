require "rake"
require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rubocop/rake_task'

Dir["lib/tasks/*.rake"].each { |rake| load rake }

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace']
end

RuboCop::RakeTask.new.tap do |task|
  if RUBY_ENGINE == 'ruby' &&
     RbConfig::CONFIG['host_os'] !~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    task.options = %w[--parallel]
  end
end

task default: 'spec'
