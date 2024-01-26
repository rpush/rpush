class Rpush710Updates < ActiveRecord::Migration["#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"]
  def self.up
    add_column :rpush_apps, :firebase_project_id, :string
    add_column :rpush_apps, :json_key, :text
  end

  def self.down
    remove_column :rpush_apps, :firebase_project_id
    remove_column :rpush_apps, :json_key
  end
end

