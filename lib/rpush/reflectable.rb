module Rpush
  module Reflectable
    def reflect(name, *args)
      Rpush.reflection_stack.each do |reflection_collection|
        reflection_collection.__dispatch(name, *args)
      end
    rescue StandardError => e
      Rpush.logger.error(e)
    end
  end
end
