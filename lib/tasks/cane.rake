begin
  require 'cane/rake_task'

  desc "Run cane to check quality metrics"
  Cane::RakeTask.new(:quality) do |cane|
    cane.add_threshold 'coverage/covered_percent', :>=, 100
    cane.no_style = false
    cane.style_measure = 1000
    cane.no_doc = true
    cane.abc_max = 15

    cane.abc_exclude = %w()
  end

  namespace :spec do
    task :cane => ['spec', 'quality']
  end
rescue LoadError
  warn "cane not available, quality task not provided."
end