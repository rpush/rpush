module Rpush
  module Client
    module ActiveModel
      module Adm
        module Notification
          def self.included(base)
            base.instance_eval do
              validates :registration_ids, presence: true

              validates_with Rpush::Client::ActiveModel::PayloadDataSizeValidator, limit: 6144
              validates_with Rpush::Client::ActiveModel::RegistrationIdsCountValidator, limit: 100

              validates_with Rpush::Client::ActiveModel::Adm::DataValidator
            end
          end

          def as_json
            json = {
              'data' => data
            }

            if collapse_key
              json['consolidationKey'] = collapse_key
            end

            # number of seconds before message is expired
            if expiry
              json['expiresAfter'] = expiry
            end

            json
          end
        end
      end
    end
  end
end
