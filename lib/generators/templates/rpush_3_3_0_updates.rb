class Rpush330Updates < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :thread_id, :string, null: true
  end

  def self.down
    remove_column :rpush_notifications, :thread_id
  end
end
