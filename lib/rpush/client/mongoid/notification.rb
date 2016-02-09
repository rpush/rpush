module Rpush
  module Client
    module Mongoid
      class Notification
        include ::Mongoid::Document
        include ::Mongoid::Timestamps
        include ::Mongoid::Autoinc
        include Rpush::MultiJsonHelper
        include Rpush::Client::ActiveModel::Notification

        field :badge, type: Integer
        field :device_token, type: String
        field :sound, type: String, default: 'default'
        field :alert, type: String
        field :data, type: Hash
        field :expiry, type: Integer, default: 1.day.to_i
        field :delivered, type: Boolean, default: false
        field :delivered_at, type: Time
        field :processing, type: Boolean, default: false
        field :failed, type: Boolean, default: false
        field :failed_at, type: Time
        field :fail_after, type: Time
        field :retries, type: Integer, default: 0
        field :error_code, type: Integer
        field :error_description, type: String
        field :deliver_after, type: Time
        field :alert_is_json, type: Boolean
        field :collapse_key, type: String
        field :delay_while_idle, type: Boolean
        field :registration_ids, type: Array
        field :uri, type: String
        field :priority, type: Integer
        field :url_args, type: Array
        field :category, type: String
        field :content_available, type: Boolean, default: false
        field :notification, type: Hash

        field :integer_id, type: Integer
        increments :integer_id, model_name: name
        index integer_id: 1

        index delivered: 1, failed: 1, deliver_after: 1, processing: 1
        index delivered: 1, failed: 1
        index device_token: 1
        index app_id: 1

        belongs_to :app
      end
    end
  end
end
