module Rpush
  module Client
    module ActiveRecord
      module Apns
        class Notification < Rpush::Client::ActiveRecord::Notification
          include Deprecatable
          include Rpush::Client::ActiveModel::Apns::Notification

          def alert=(alert)
            if alert.is_a?(Hash)
              write_attribute(:alert, multi_json_dump(alert))
              self.alert_is_json = true if has_attribute?(:alert_is_json)
            else
              write_attribute(:alert, alert)
              self.alert_is_json = false if has_attribute?(:alert_is_json)
            end
          end

          def alert
            string_or_json = read_attribute(:alert)

            if has_attribute?(:alert_is_json)
              if alert_is_json?
                multi_json_load(string_or_json)
              else
                string_or_json
              end
            else
              begin
                multi_json_load(string_or_json)
              rescue StandardError
                string_or_json
              end
            end
          end
        end
      end
    end
  end
end
