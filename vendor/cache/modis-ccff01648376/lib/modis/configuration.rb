module Modis
  def self.configure
    yield config
  end

  def self.config
    @config ||= Configuration.new
  end

  class Configuration < Struct.new(:namespace)
  end
end
