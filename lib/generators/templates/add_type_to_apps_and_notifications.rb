class AddTypeToAppsAndNotifications < ActiveRecord::Migration
  module Rapns
    class Notification < ActiveRecord::Base
      self.table_name = 'rapns_notifications'
    end

    class App < ActiveRecord::Base;
      self.table_name = 'rapns_apps'
    end
  end

  def self.up
    add_column :rapns_notifications, :type, :string, :null => true
    add_column :rapns_apps, :type, :string, :null => true

    Rapns::Notification.update_all :type => 'Rapns::Apns::Notification'
    Rapns::App.update_all :type => 'Rapns::Apns::App'

    change_column_null :rapns_notifications, :type, false
    change_column_null :rapns_apps, :type, false
  end

  def self.down
    remove_column :rapns_notifications, :type
    remove_column :rapns_apps, :type
  end
end