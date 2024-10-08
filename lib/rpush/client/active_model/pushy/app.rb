module Rpush
  module Client
    module ActiveModel
      module Pushy
        module App
          def self.included(base)
            base.instance_eval do
              # alias_attribute :api_key, :auth_key # Removed due to a breaking change in rails 7.2. Waiting for a fix to be implemented
              validates :api_key, presence: true
            end
          end

          def api_key
            auth_key
          end

          def api_key=(value)
            self.auth_key = value
          end

          def service_name
            'pushy'
          end
        end
      end
    end
  end
end
