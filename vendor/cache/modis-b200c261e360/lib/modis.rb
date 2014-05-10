require 'redis'
require 'active_model'
require 'active_support/all'
require 'multi_json'

require 'modis/version'
require 'modis/configuration'
require 'modis/attributes'
require 'modis/errors'
require 'modis/persistence'
require 'modis/transaction'
require 'modis/finders'
require 'modis/model'

module Modis
  @mutex = Mutex.new

  def self.redis
    return @redis if @redis
    @mutex.synchronize { @redis = Redis.new }
    @redis
  end

  def self.redis=(redis)
    @redis = redis
  end
end
