class AddProcessingToRpushNotifications < ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :processing, :boolean, null: false, default: false
  end

  def self.down
    remove_column :rpush_notifications, :processing
  end
end
