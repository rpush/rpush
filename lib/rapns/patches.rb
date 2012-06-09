if Rails::VERSION::STRING == '3.1.0' || Rails::VERSION::STRING == '3.1.1'
  if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'postgresql'
    STDERR.puts "[WARNING] Detected Rails #{Rails::VERSION::STRING}, patching PostgreSQLAdapter to fix reconnection bug: https://github.com/rails/rails/issues/3160"
    require "rapns/patches/rails/#{Rails::VERSION::STRING}/postgresql_adapter.rb"
  end
end