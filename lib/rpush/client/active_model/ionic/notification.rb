module Rpush
  module Client
    module ActiveModel
      module Ionic
        module Notification
          def self.included(base)
            base.instance_eval do
              alias_attribute :device_tokens, :registration_ids

              validates :device_tokens, :profile, presence: true
            end
          end

          def as_json
            {
              tokens: device_tokens,
              profile: profile,
              notification: notification
            }
          end
        end
      end
    end
  end
end
