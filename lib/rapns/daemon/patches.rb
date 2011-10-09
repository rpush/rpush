if defined?(Rails) && ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'postgresql'
  if Rails::VERSION::STRING == '3.1.0' || Rails::VERSION::STRING == '3.1.1'
    STDERR.puts '[WARNING] Patched PostgreSQLAdapter to fix reconnection bug: https://github.com/rails/rails/issues/3160.'
    require "rapns/daemon/patches/rails/#{Rails::VERSION::STRING}/postgresql_adapter.rb"
  end
end