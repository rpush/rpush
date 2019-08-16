class Rpush301Updates < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration
  def self.up
    change_column_null :rpush_notifications, :mutable_content, false
    change_column_null :rpush_notifications, :content_available, false
    change_column_null :rpush_notifications, :alert_is_json, false
  end

  def self.down
    change_column_null :rpush_notifications, :mutable_content, true
    change_column_null :rpush_notifications, :content_available, true
    change_column_null :rpush_notifications, :alert_is_json, true
  end
end
