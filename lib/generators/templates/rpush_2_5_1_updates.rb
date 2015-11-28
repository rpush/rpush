class Rpush251Updates < ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :content_available, :boolean, default: false
  end

  def self.down
    remove_column :rpush_notifications, :content_available
  end
end
