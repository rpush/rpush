module Rpush
  module Client
    module ActiveModel
      module Ionic
        module App
          def self.included(base)
            base.instance_eval do
              validates :auth_key, presence: true
            end
          end

          def service_name
            'ionic'
          end
        end
      end
    end
  end
end
