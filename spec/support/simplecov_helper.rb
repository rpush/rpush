require 'simplecov'
require './spec/support/simplecov_quality_formatter'

module SimpleCovHelper
  def start_simple_cov(name)
    SimpleCov.start do
      add_filter '/spec/'
      add_filter '/lib/generators'
      command_name name
      formatter SimpleCov::Formatter::QualityFormatter
    end
  end
end