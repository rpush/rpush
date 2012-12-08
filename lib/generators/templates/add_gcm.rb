class AddGcm < ActiveRecord::Migration
  module Rapns
    class App < ActiveRecord::Base
      self.table_name = 'rapns_apps'
    end

    class Notification < ActiveRecord::Base
      belongs_to :app
      self.table_name = 'rapns_notifications'
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
    change_column_null :rapns_notifications, :expiry, true
    change_column_null :rapns_apps, :environment, true
    change_column_null :rapns_apps, :certificate, true

    change_column :rapns_notifications, :error_description, :text
    change_column :rapns_notifications, :sound, :string, :default => 'default'

    rename_column :rapns_notifications, :attributes_for_device, :data
    rename_column :rapns_apps, :key, :name

    add_column :rapns_apps, :auth_key, :string, :null => true

    add_column :rapns_notifications, :collapse_key, :string, :null => true
    add_column :rapns_notifications, :delay_while_idle, :boolean, :null => false, :default => false
    add_column :rapns_notifications, :registration_ids, :text, :null => true
    add_column :rapns_notifications, :app_id, :integer, :null => true
    add_column :rapns_notifications, :retries, :integer, :null => true, :default => 0

    Rapns::Notification.reset_column_information
    Rapns::App.reset_column_information

    Rapns::App.all.each do |app|
      Rapns::Notification.update_all(['app_id = ?', app.id], ['app = ?', app.name])
    end

    change_column_null :rapns_notifications, :app_id, false
    remove_column :rapns_notifications, :app
  end

  def self.down
    AddGcm::Rapns::Notification.where(:type => 'Rapns::Gcm::Notification').delete_all

    remove_column :rapns_notifications, :type
    remove_column :rapns_apps, :type

    change_column_null :rapns_notifications, :device_token, false
    change_column_null :rapns_notifications, :expiry, false
    change_column_null :rapns_apps, :environment, false
    change_column_null :rapns_apps, :certificate, false

    change_column :rapns_notifications, :error_description, :string

    rename_column :rapns_notifications, :data, :attributes_for_device
    rename_column :rapns_apps, :name, :key

    remove_column :rapns_apps, :auth_key

    remove_column :rapns_notifications, :collapse_key
    remove_column :rapns_notifications, :delay_while_idle
    remove_column :rapns_notifications, :registration_ids
    remove_column :rapns_notifications, :retries

    add_column :rapns_notifications, :app, :string, :null => true

    Rapns::Notification.reset_column_information
    Rapns::App.reset_column_information

    Rapns::App.all.each do |app|
      Rapns::Notification.update_all(['app = ?', app.key], ['app_id = ?', app.id])
    end

    change_column_null :rapns_notifications, :key, false
    remove_column :rapns_notifications, :app_id
  end
end
