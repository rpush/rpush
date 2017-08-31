class Rpush270Updates < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration
  def self.up
    change_column :rpush_notifications, :alert, :text
    add_column :rpush_notifications, :notification, :text
  end

  def self.down
    change_column :rpush_notifications, :alert, :string
    remove_column :rpush_notifications, :notification
  end
end

