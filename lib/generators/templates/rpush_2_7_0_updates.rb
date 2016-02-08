class Rpush270Updates < ActiveRecord::Migration
  def self.up
    change_column :rpush_notifications, :alert, :text
  end

  def self.down
    change_column :rpush_notifications, :alert, :string
  end
end

