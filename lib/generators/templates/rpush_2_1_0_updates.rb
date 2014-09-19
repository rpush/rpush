class Rpush210Updates < ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :url_args, :text, null: true
  end

  def self.down
    remove_column :rpush_notifications, :url_args
  end
end
