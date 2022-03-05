module Rpush
  module Client
    module ActiveModel
      module Hms
        module Notification
          CLICK_CUSTOM = 1
          CLICK_URL = 2
          CLICK_START_APP = 3
          CLICK_RICH_MEDIA = 4
          CLICK_ACTIONS = [CLICK_CUSTOM, CLICK_URL, CLICK_START_APP, CLICK_RICH_MEDIA].freeze
          PRIORITY = {
            1 => 'HIGH',
            10 => 'NORMAL'
          }
          COLLAPSE_KEYS = (-1..100).to_a.freeze

          def set_uri(hms_app_id)
            self.uri = "https://push-api.cloud.huawei.com/v1/#{hms_app_id}/messages:send"
          end

          # @param [Hash] action
          def validate_click_action(action = nil)
            action = action || self.notification&.dig('click_action') || {}
            return self.errors.add(:notification,'"click_action" must be a hash') unless action.is_a?(Hash)
            return self.errors.add(:notification,'Key "type" is required in "click_action"') unless action.key?('type')
            self.errors.add(:notification,"#{action['type']} is not a valid click action type") unless action['type'].in?(CLICK_ACTIONS)
          end

          def priority=(priority)
            priority = priority.is_a?(Integer) ? PRIORITY[priority] : priority&.upcase
            case priority
            when *PRIORITY.values
              super(PRIORITY.key(priority))
            else
              errors.add(:priority, 'must be one of either "high" or "normal"')
            end
          end

          def collapse_key=(key)
            return self.errors.add(:collapse_key,"#{key} is not a valid collapse key") unless key.in?(COLLAPSE_KEYS)
            super(key.to_s)
          end

          def notification
            super || {}
          end

          # @param [Hash] action
          def click_action=(action)
            validate_click_action(action || {})
            notif = notification || {}
            self.notification = notif.merge('click_action' => action)
          end

          def default_click_action
            {
              'type' => CLICK_START_APP
            }
          end

          def as_json(options = nil)
            json = {
              'validate_only' => test_only,
              'message' => {},
            }
            json['message']['android'] = {}
            json['message']['android']['collapse_key'] = collapse_key.to_i if collapse_key
            json['message']['android']['urgency'] = PRIORITY[priority] if priority
            json['message']['token'] = self.registration_ids
            json['message']['data'] = self.data.to_json

            json['message']['android']['notification'] = notification.merge(
              'title' => title,
              'body' => body
            ) if notification.present?
            json
          end

          def self.included(base)
            base.instance_eval do
              attribute :title, :string
              attribute :body, :string
              attribute :test_only, :boolean, default: false

              validates :app_id, presence: true
              validates_with Rpush::Client::ActiveModel::RegistrationIdsCountValidator, limit: 1000
            end
          end
        end
      end
    end
  end
end
