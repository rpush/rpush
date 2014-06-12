begin
  require 'cane/rake_task'

  desc 'Run cane to check quality metrics'
  Cane::RakeTask.new(:cane_quality) do |cane|
    cane.add_threshold 'coverage/covered_percent', :>=, 98
    cane.no_style = false
    cane.style_measure = 1000
    cane.no_doc = true
    cane.abc_max = 20
  end

  namespace :spec do
    task :cane => ['spec', 'cane_quality']
  end
rescue LoadError
  warn "cane not available."

  namespace :spec do
    task :cane => ['spec']
  end
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  warn 'rubocop not available.'
  task :rubocop => ['spec']
end

namespace :spec do
  task quality: ['cane', 'rubocop']
end
