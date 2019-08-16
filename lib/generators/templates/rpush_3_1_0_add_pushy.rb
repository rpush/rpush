class Rpush310AddPushy < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :external_device_id, :string, null: true
  end

  def self.down
    remove_column :rpush_notifications, :external_device_id
  end
end
