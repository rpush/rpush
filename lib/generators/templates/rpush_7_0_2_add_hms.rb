# migration 3_1_1_a is mapped to version 3.1.1.1
class Rpush702AddHms < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration
  def self.up
    add_column :rpush_apps, :hms_app_id, :string
    add_column :rpush_apps, :hms_key_id, :string
    add_column :rpush_apps, :hms_sub_acc_id, :string
    add_column :rpush_apps, :hms_key, :string
    add_column :rpush_notifications, :title, :string
    add_column :rpush_notifications, :test_only, :boolean
    add_column :rpush_notifications, :body, :string
  end

  def self.down
    remove_column :rpush_apps, :hms_app_id
    remove_column :rpush_apps, :hms_key_id
    remove_column :rpush_apps, :hms_sub_acc_id
    remove_column :rpush_apps, :hms_key
    remove_column :rpush_notifications, :title
    remove_column :rpush_notifications, :test_only
    remove_column :rpush_notifications, :body
  end
end
