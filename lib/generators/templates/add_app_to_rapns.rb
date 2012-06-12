class AddAppToRapns < ActiveRecord::Migration
  def self.up
    add_column :rapns_notifications, :app, :string, :null => false, :default => 'app'
    add_column :rapns_feedback, :app, :string, :null => false, :default => 'app'
  end

  def self.down
    remove_column :rapns_notifications, :app
    remove_column :rapns_feedback, :app
  end
end