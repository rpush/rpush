require 'acceptance_spec_helper'

describe 'GCM upgrade' do
  before do
    setup_rails
    generate
    migrate('create_rapns_notifications', 'create_rapns_feedback',
      'add_alert_is_json_to_rapns_notifications', 'add_app_to_rapns',
      'create_rapns_apps')

    as_test_rails_db do
      now = Time.now.to_s(:db)
      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO rapns_apps (key, environment, certificate, created_at, updated_at)
          VALUES ('test', 'development', 'c3rt', '#{now}', '#{now}')
      SQL

      ActiveRecord::Base.connection.execute <<-SQL
        INSERT INTO rapns_notifications (app, device_token, created_at, updated_at)
          VALUES ('test', 't0k3n', '#{now}', '#{now}')
      SQL
    end

    migrate('add_gcm')
  end

  it 'associates apps and notifications' do
    as_test_rails_db do
      app = Rapns::Apns::App.first
      app.name.should == 'test'
      app.notifications.count.should == 1
    end
  end
end
