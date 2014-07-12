class Rpush200Updates < ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :processing, :boolean, null: false, default: false
    add_column :rpush_notifications, :priority, :integer, null: true
  end

  def self.down
    remove_column :rpush_notifications, :processing
    remove_column :rpush_notifications, :priority
  end
end
