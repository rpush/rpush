class AddAlertIsJsonToRapnsNotifications < ActiveRecord::Migration
  def self.up
    add_column :rapns_notifications, :alert_is_json, :boolean, :null => true, :default => false
  end

  def self.down
    remove_column :rapns_notifications, :alert_is_json
  end
end