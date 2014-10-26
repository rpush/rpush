module Rpush
  def self.plugin(name)
    plugins[name] ||= Rpush::Plugin.new(name)
    plugins[name]
  end

  def self.plugins
    @plugins ||= {}
  end

  class Plugin
    attr_reader :config
    attr_accessor :name, :url, :description

    def initialize(name)
      @name = name
      @url = nil
      @description = nil
      @config = OpenStruct.new
      @reflection_collection = Rpush::ReflectionCollection.new
    end

    def reflect
      yield(@reflection_collection)
      return if Rpush.reflection_stack.include?(@reflection_collection)
      Rpush.reflection_stack << @reflection_collection
    end

    def configure
      yield(@config)
      Rpush.config.plugin.send("#{@name}=", @config)
    end

    def unload
    end
  end
end
