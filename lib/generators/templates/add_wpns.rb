class AddWpns < ActiveRecord::Migration
  def self.up
    add_column :rapns_notifications, :uri, :string, :null => true
  end

  def self.down
    AddWpns::Rapns::Notification.where(:type => 'Rapns::Wpns::Notification').delete_all
    remove_column :rapns_notifications, :uri
  end
end
