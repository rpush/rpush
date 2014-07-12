class Rpush200Updates < ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :processing, :boolean, null: false, default: false
    add_column :rpush_notifications, :priority, :integer, null: true

    if index_name_exists?(:rpush_notifications, :index_rpush_notifications_multi, true)
      remove_index :rpush_notifications, name: :index_rpush_notifications_multi
    end

    add_index :rpush_notifications, [:processing, :delivered, :failed, :deliver_after], name: 'index_rpush_notifications_multi'
  end

  def self.down
    if index_name_exists?(:rpush_notifications, :index_rpush_notifications_multi, true)
      remove_index :rpush_notifications, name: :index_rpush_notifications_multi
    end

    add_index :rpush_notifications, [:app_id, :delivered, :failed, :deliver_after], name: 'index_rpush_notifications_multi'

    remove_column :rpush_notifications, :priority
    remove_column :rpush_notifications, :processing
  end
end
