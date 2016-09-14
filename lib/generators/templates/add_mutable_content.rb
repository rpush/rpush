class AddMutableContentToRpushNotifications < ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :mutable_content, :boolean, null: false, default: false
  end

  def self.down
    remove_column :rpush_notifications, :mutable_content
  end
end
