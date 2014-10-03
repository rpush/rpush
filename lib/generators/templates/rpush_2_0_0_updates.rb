class Rpush200Updates < ActiveRecord::Migration
  def self.up
    add_column :rpush_notifications, :processing, :boolean, null: false, default: false
    add_column :rpush_notifications, :priority, :integer, null: true

    if index_name_exists?(:rpush_notifications, :index_rpush_notifications_multi, true)
      remove_index :rpush_notifications, name: :index_rpush_notifications_multi
    end

    add_index :rpush_notifications, [:delivered, :failed], name: 'index_rpush_notifications_multi', where: 'NOT delivered AND NOT failed'

    rename_column :rpush_feedback, :app, :app_id

    if postgresql?
      execute('ALTER TABLE rpush_feedback ALTER COLUMN app_id TYPE integer USING (trim(app_id)::integer)')
    else
      change_column :rpush_feedback, :app_id, :integer
    end
  end

  def self.down
    change_column :rpush_feedback, :app_id, :string
    rename_column :rpush_feedback, :app_id, :app

    if index_name_exists?(:rpush_notifications, :index_rpush_notifications_multi, true)
      remove_index :rpush_notifications, name: :index_rpush_notifications_multi
    end

    add_index :rpush_notifications, [:app_id, :delivered, :failed, :deliver_after], name: 'index_rpush_notifications_multi'

    remove_column :rpush_notifications, :priority
    remove_column :rpush_notifications, :processing
  end

  def self.adapter_name
    env = (defined?(Rails) && Rails.env) ? Rails.env : 'development'
    ActiveRecord::Base.configurations[env]['adapter']
  end

  def self.postgresql?
    adapter_name =~ /postgresql|postgis/
  end
end
