module Rpush
  module Client
    module ActiveModel
      module Hms
        module App
          def service_name
            'hms'
          end

          def self.included(base)
            base.instance_eval do
              validates :hms_app_id, presence: true
              validates :hms_key_id, presence: true
              validates :hms_sub_acc_id, presence: true
              validates :hms_key, presence: true
            end
          end
        end
      end
    end
  end
end
