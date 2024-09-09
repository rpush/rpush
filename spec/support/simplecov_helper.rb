require 'simplecov'
require './spec/support/simplecov_quality_formatter'

module SimpleCovHelper
  def start_simple_cov(name)
    SimpleCov.start do
      add_filter '/spec/'
      add_filter '/lib/generators'
      command_name name

      formatters = [SimpleCov::Formatter::QualityFormatter]

      if ENV['CI']
        require 'codeclimate-test-reporter'

        formatters << CodeClimate::TestReporter::Formatter if CodeClimate::TestReporter.run?
      end

      formatter SimpleCov::Formatter::MultiFormatter.new(formatters)
    end
  end
end
