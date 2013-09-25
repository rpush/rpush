class AddAdm < ActiveRecord::Migration
  def self.up
    add_column :rapns_apps, :client_id, :string, :null => true
    add_column :rapns_apps, :client_secret, :string, :null => true
    add_column :rapns_apps, :access_token, :string, :null => true
    add_column :rapns_apps, :access_token_expiration, :datetime, :null => true
  end

  def self.down
    AddGcm::Rapns::Notification.where(:type => 'Rapns::Adm::Notification').delete_all

    remove_column :rapns_apps, :client_id
    remove_column :rapns_apps, :client_secret
    remove_column :rapns_apps, :access_token
    remove_column :rapns_apps, :access_token_expiration
  end
end
