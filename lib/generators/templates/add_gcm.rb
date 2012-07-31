class AddGcm < ActiveRecord::Migration
  module Rapns
    class Notification < ActiveRecord::Base
      serialize :apps
      self.table_name = 'rapns_notifications'
    end

    class App < ActiveRecord::Base
      self.table_name = 'rapns_apps'
    end
  end

  def self.up
    add_column :rapns_notifications, :type, :string, :null => true
    add_column :rapns_apps, :type, :string, :null => true

    AddGcm::Rapns::Notification.update_all :type => 'Rapns::Apns::Notification'
    AddGcm::Rapns::App.update_all :type => 'Rapns::Apns::App'

    change_column_null :rapns_notifications, :type, false
    change_column_null :rapns_apps, :type, false
    change_column_null :rapns_notifications, :device_token, true

    rename_column :rapns_notifications, :attributes_for_device, :data

    add_column :rapns_notifications, :collapse_key, :string, :null => true
    add_column :rapns_notifications, :delay_while_idle, :boolean, :null => false, :default => false
    add_column :rapns_notifications, :auth_key, :string, :null => true

    add_column :rapns_apps, :registration_id, :string, :null => true
  end

  def self.down
    AddGcm::Rapns::Notification.where(:type => 'Rapns::Gcm::Notification').delete_all

    remove_column :rapns_notifications, :type
    remove_column :rapns_apps, :type

    change_column_null :rapns_notifications, :device_token, false

    rename_column :rapns_notifications, :data, :attributes_for_device

    remove_column :rapns_notifications, :collapse_key
    remove_column :rapns_notifications, :delay_while_idle
    remove_column :rapns_notifications, :auth_key

    remove_column :rapns_apps, :registration_id
  end
end
