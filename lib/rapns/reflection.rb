module Rapns
  def self.reflect
    yield reflections if block_given?
  end

  def self.reflections
    @reflections ||= Reflections.new
  end

  class Reflections
    class NoSuchReflectionError < StandardError; end

    REFLECTIONS = [
      :apns_feedback, :notification_enqueued, :notification_delivered,
      :notification_failed, :notification_will_retry, :apns_connection_lost,
      :error
    ]

    REFLECTIONS.each do |reflection|
      class_eval(<<-RUBY, __FILE__, __LINE__)
        def #{reflection}(*args)
          if reflections[:#{reflection}]
            reflections[:#{reflection}].call(*args)
          end
        end
      RUBY

      class_eval(<<-RUBY, __FILE__, __LINE__)
        def #{reflection}=(&blk)
          reflections[:#{reflection}] = blk
        end
      RUBY
    end

    def __dispatch(reflection, *args)
      unless REFLECTIONS.include?(reflection.to_sym)
        raise NoSuchReflectionError, reflection
      end
      send(reflection, *args)
    end

    private

    def reflections
      @reflections ||= {}
    end
  end
end
