class AddAppToRapnsNotifications < ActiveRecord::Migration
  def self.up
    add_column :rapns_notifications, :app, :string, :null => false, :default => 'app'
  end

  def self.down
    remove_column :rapns_notifications, :app
  end
end