begin
  require './spec/support/simplecov_helper'
  include SimpleCovHelper
  start_simple_cov('unit')
rescue LoadError
  puts "Coverage disabled."
end

require 'modis'

Modis.configure do |config|
  config.namespace = 'modis'
end

RSpec.configure do |config|
  config.after :each do
    keys = Redis.current.keys "#{Modis.config.namespace}:*"
    Redis.current.del *keys unless keys.empty?
  end
end
