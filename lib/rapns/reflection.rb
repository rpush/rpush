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
      :gcm_canonical_id, :gcm_invalid_registration_id, :error, :apns_certificate_will_expire
    ]

    REFLECTIONS.each do |reflection|
      class_eval(<<-RUBY, __FILE__, __LINE__)
        def #{reflection}(*args, &blk)
          raise "block required" unless block_given?
          reflections[:#{reflection}] = blk
        end
      RUBY
    end

    def __dispatch(reflection, *args)
      unless REFLECTIONS.include?(reflection.to_sym)
        raise NoSuchReflectionError, reflection
      end

      if reflections[reflection]
        reflections[reflection].call(*args)
      end
    end

    private

    def reflections
      @reflections ||= {}
    end
  end
end
