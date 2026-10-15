class Rpush930Updates < ActiveRecord::Migration["#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"]
  def self.up
    add_column :rpush_notifications, :device_token_is_fid, :boolean, null: false, default: false
  end

  def self.down
    remove_column :rpush_notifications, :device_token_is_fid
  end
end
