class CreateRapnsApps < ActiveRecord::Migration
  def self.up
    create_table :rapns_apps do |t|
      t.string    :key,         :null => false
      t.string    :environment, :null => false
      t.text      :certificate, :null => false
      t.string    :password,    :null => true
      t.integer   :connections, :null => false, :default => 1
      t.timestamps
    end

    add_index :rapns_apps, :environment
    add_index :rapns_apps, :key
  end

  def self.down
    drop_table :rapns_apps
  end
end
