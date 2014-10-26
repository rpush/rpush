module Rpush
  def self.reflect
    yield reflection_stack[0] if block_given?
  end

  def self.reflection_stack
    @reflection_stack ||= [ReflectionCollection.new]
  end
end
