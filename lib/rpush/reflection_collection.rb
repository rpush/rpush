module Rpush
  class ReflectionCollection
    class NoSuchReflectionError < StandardError; end

    REFLECTIONS = [
      :apns_feedback, :notification_enqueued, :notification_delivered,
      :notification_failed, :notification_will_retry, :gcm_delivered_to_recipient,
      :gcm_failed_to_recipient, :gcm_canonical_id, :gcm_invalid_registration_id,
      :error, :adm_canonical_id, :adm_failed_to_recipient,
      :tcp_connection_lost, :ssl_certificate_will_expire, :ssl_certificate_revoked,
      :notification_id_will_retry, :notification_id_failed
    ]

    DEPRECATIONS = {}

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
        fail NoSuchReflectionError, reflection
      end

      if DEPRECATIONS.key?(reflection)
        replacement, removal_version = DEPRECATIONS[reflection]
        Rpush::Deprecation.warn("#{reflection} is deprecated and will be removed in version #{removal_version}. Use #{replacement} instead.")
      end

      reflections[reflection].call(*args) if reflections[reflection]
    end

    private

    def reflections
      @reflections ||= {}
    end
  end
end
