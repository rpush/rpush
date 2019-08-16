class Rpush410Updates < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration["#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"] : ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :dry_run, :boolean, null: false, default: false
  end

  def self.down
    remove_column :rpush_notifications, :dry_run
  end
end
