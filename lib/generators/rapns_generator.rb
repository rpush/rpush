class RapnsGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def copy_migration
     migration_template "create_rapns_notifications.rb", "db/migrate/create_rapns_notifications.rb"
  end

  def copy_config
    copy_file "rapns.yml", "config/rapns/rapns.yml"
  end
end