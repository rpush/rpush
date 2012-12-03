require "rake"
require "bundler/gem_tasks"
require "rspec/core/rake_task"
Dir["lib/tasks/*.rake"].each { |rake| load rake }

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace']
end

if RUBY_VERSION > '1.8'
  task :default => 'spec:cane'
end
