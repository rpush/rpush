module Rpush
  module Client
    module ActiveModel
      module Apns
        module Notification
          APNS_DEFAULT_EXPIRY = 1.day.to_i
          APNS_PRIORITY_IMMEDIATE = 10
          APNS_PRIORITY_CONSERVE_POWER = 5
          APNS_PRIORITIES = [APNS_PRIORITY_IMMEDIATE, APNS_PRIORITY_CONSERVE_POWER]

          def self.included(base)
            base.instance_eval do
              validates :device_token, presence: true
              validates :badge, numericality: true, allow_nil: true
              validates :priority, inclusion: { in: APNS_PRIORITIES }, allow_nil: true

              validates_with Rpush::Client::ActiveModel::Apns::DeviceTokenFormatValidator
              validates_with Rpush::Client::ActiveModel::Apns::BinaryNotificationValidator

              base.const_set('APNS_DEFAULT_EXPIRY', APNS_DEFAULT_EXPIRY) unless base.const_defined?('APNS_DEFAULT_EXPIRY')
              base.const_set('APNS_PRIORITY_IMMEDIATE', APNS_PRIORITY_IMMEDIATE) unless base.const_defined?('APNS_PRIORITY_IMMEDIATE')
              base.const_set('APNS_PRIORITY_CONSERVE_POWER', APNS_PRIORITY_CONSERVE_POWER) unless base.const_defined?('APNS_PRIORITY_CONSERVE_POWER')
            end
          end

          def device_token=(token)
            write_attribute(:device_token, token.delete(" <>")) unless token.nil?
          end

          MDM_KEY = '__rpush_mdm__'
          def mdm=(magic)
            self.data = (data || {}).merge(MDM_KEY => magic)
          end

          CONTENT_AVAILABLE_KEY = '__rpush_content_available__'
          def content_available=(bool)
            return unless bool
            self.data = (data || {}).merge(CONTENT_AVAILABLE_KEY => true)
          end

          def as_json(options = nil) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
            json = ActiveSupport::OrderedHash.new

            if data && data.key?(MDM_KEY)
              json['mdm'] = data[MDM_KEY]
            else
              json['aps'] = ActiveSupport::OrderedHash.new
              json['aps']['alert'] = alert if alert
              json['aps']['badge'] = badge if badge
              json['aps']['sound'] = sound if sound
              json['aps']['category'] = category if category
              json['aps']['url-args'] = url_args if url_args

              if data && data[CONTENT_AVAILABLE_KEY]
                json['aps']['content-available'] = 1
              end

              if data
                non_aps_attributes = data.reject { |k, _| k == CONTENT_AVAILABLE_KEY }
                non_aps_attributes.each { |k, v| json[k.to_s] = v }
              end
            end

            json
          end

          def to_binary(options = {})
            frame_payload = payload
            frame_id = options[:for_validation] ? 0 : send(options.fetch(:id_attribute, :id))
            frame = ""
            frame << [1, 32, device_token].pack("cnH*")
            frame << [2, frame_payload.bytesize, frame_payload].pack("cna*")
            frame << [3, 4, frame_id].pack("cnN")
            frame << [4, 4, expiry || APNS_DEFAULT_EXPIRY].pack("cnN")
            frame << [5, 1, priority_for_frame].pack("cnc")
            [2, frame.bytesize].pack("cN") + frame
          end

          private

          def priority_for_frame
            # It is an error to use APNS_PRIORITY_IMMEDIATE for a notification that only contains content-available.
            if as_json['aps'].try(:keys) == ['content-available']
              APNS_PRIORITY_CONSERVE_POWER
            else
              priority || APNS_PRIORITY_IMMEDIATE
            end
          end
        end
      end
    end
  end
end
