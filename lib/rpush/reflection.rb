module Rpush
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
      :gcm_delivered_to_recipient, :gcm_failed_to_recipient, :gcm_canonical_id,
      :gcm_invalid_registration_id, :error, :apns_certificate_will_expire,
      :adm_canonical_id, :tcp_connection_lost, :ssl_certificate_will_expire
    ]

    DEPRECATIONS = {
      apns_connection_lost: [:tcp_connection_lost, '4.1'],
      apns_certificate_will_expire: [:ssl_certificate_will_expire, '4.1']
    }

    REFLECTIONS.each do |reflection|
      class_eval(<<-RUBY, __FILE__, __LINE__)
        def #{reflection}(*args, &blk)
          raise "block required" unless block_given?
          reflections[:#{reflection}] = blk
        end
      RUBY
    end

    def __dispatch(reflection, *args)
      reflection = reflection.to_sym

      unless REFLECTIONS.include?(reflection)
        raise NoSuchReflectionError, reflection
      end

      if DEPRECATIONS.key?(reflection)
        replacement, removal_version = DEPRECATIONS[reflection]
        Rpush::Deprecation.warn("#{reflection} is deprecated and will be removed in version #{removal_version}. Use #{replacement} instead.")
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
