class AddWpns < ActiveRecord::Migration
  def self.up
    add_column :rapns_notifications, :uri, :string, :null => true
  end

  def self.down
    ::Rpush::Notification.where(:type => 'Rpush::Wpns::Notification').delete_all
    remove_column :rapns_notifications, :uri
  end
end
