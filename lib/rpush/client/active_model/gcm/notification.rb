module Rpush
  module Client
    module ActiveModel
      module Gcm
        module Notification
          def self.included(base)
            base.instance_eval do
              validates :registration_ids, presence: true
              validates :priority, inclusion: { in: Rpush::Client::ActiveModel::Apns::Notification::APNS_PRIORITIES }, allow_nil: true

              validates_with Rpush::Client::ActiveModel::PayloadDataSizeValidator, limit: 4096
              validates_with Rpush::Client::ActiveModel::RegistrationIdsCountValidator, limit: 1000

              validates_with Rpush::Client::ActiveModel::Gcm::ExpiryCollapseKeyMutualInclusionValidator
            end
          end

          def as_json
            json = {
              'registration_ids' => registration_ids,
              'delay_while_idle' => delay_while_idle,
              'data' => data
            }
            json['collapse_key'] = collapse_key if collapse_key
            json['time_to_live'] = expiry if expiry

            # see https://developers.google.com/cloud-messaging/http-server-ref
            # GCM also supports APNS and says normal == 5 and high == 10
            # so we reuse the APNS priority here
            if priority and priority == Rpush::Client::ActiveModel::Apns::Notification::APNS_PRIORITY_IMMEDIATE
              json['priority'] = 'high'
            end

            json
          end
        end
      end
    end
  end
end
