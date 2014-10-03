class RpushMigrationGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)

  def self.next_migration_number(path)
    @time ||= Time.now.utc
    @calls ||= -1
    @calls += 1
    (@time + @calls.seconds).strftime("%Y%m%d%H%M%S")
  end

  def copy_migration
    if has_migration?('create_rapns_notifications')
      add_rpush_migration('create_rapns_feedback')
      add_rpush_migration('add_alert_is_json_to_rapns_notifications')
      add_rpush_migration('add_app_to_rapns')
      add_rpush_migration('create_rapns_apps')
      add_rpush_migration('add_gcm')
      add_rpush_migration('add_wpns')
      add_rpush_migration('add_adm')
      add_rpush_migration('rename_rapns_to_rpush')
      add_rpush_migration('add_fail_after_to_rpush_notifications')
    else
      add_rpush_migration('add_rpush')
    end

    add_rpush_migration('rpush_2_0_0_updates')
    add_rpush_migration('rpush_2_1_0_updates')
  end

  protected

  def has_migration?(template)
    migration_dir = File.expand_path('db/migrate')
    self.class.migration_exists?(migration_dir, template)
   end

  def add_rpush_migration(template)
      migration_template "#{template}.rb", "db/migrate/#{template}.rb"
  end
end
