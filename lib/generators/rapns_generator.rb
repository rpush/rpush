class RapnsGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def copy_migration
    migration_dir = File.expand_path("db/migrate")

    if !self.class.migration_exists?(migration_dir, 'create_rapns_notifications')
      migration_template "create_rapns_notifications.rb", "db/migrate/create_rapns_notifications.rb"
    end

    if !self.class.migration_exists?(migration_dir, 'create_rapns_feedback')
      migration_template "create_rapns_feedback.rb", "db/migrate/create_rapns_feedback.rb"
    end
  end

  def copy_config
    copy_file "rapns.yml", "config/rapns/rapns.yml"
  end
end