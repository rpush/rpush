ENV['RAILS_ENV'] = 'test'

require 'benchmark'
require 'bundler/setup'
Bundler.require(:default)
require 'stackprof'

$LOAD_PATH.unshift('.')
require 'lib/rpush'

puts "Profiler enabled." if ENV['PROFILE']

class Bench
  def self.run
    bench = new
    yield(bench)
    bench._run
  end

  def initialize
    @bms = []
    @profiles = []
  end

  def report(name, &blk)
    @bms << [name, blk]
  end

  def _run
    Benchmark.bmbm do |x|
      @bms.each do |name, blk|
        x.report(name) do
          with_profile(name, &blk)
        end
      end
    end

    after
  end

  private

  def with_profile(name, &blk)
    if ENV['PROFILE']
      mode = :wall
      out = "tmp/stackprof-#{mode}-#{name}.dump"
      @profiles << out
      StackProf.run(mode: mode, out: out, &blk)
    else
      blk.call
    end
  end

  def after
    return unless @profiles.any?

    puts "\nProfiler dumps:"
    @profiles.uniq.each { |dump| puts " * stackprof #{dump} --text" }
  end
end
