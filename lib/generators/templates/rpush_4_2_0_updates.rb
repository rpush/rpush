class Rpush420Updates < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration["#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"] : ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :sound_is_json, :boolean, null: true, default: false
  end

  def self.down
    remove_column :rpush_notifications, :sound_is_json
  end
end

