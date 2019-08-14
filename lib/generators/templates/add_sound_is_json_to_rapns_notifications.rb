class AddSoundIsJsonToRapnsNotifications < ActiveRecord::VERSION::MAJOR >= 5 ? ActiveRecord::Migration[5.0] : ActiveRecord::Migration
  def self.up
    add_column :rapns_notifications, :sound_is_json, :boolean, null: true, default: false
  end

  def self.down
    remove_column :rapns_notifications, :sound_is_json
  end
end
