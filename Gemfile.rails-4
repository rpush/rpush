source 'https://rubygems.org'

gem 'rake'
gem 'rspec', '= 2.14.1'
gem 'rails', '~> 4.1'
gem 'database_cleaner'
gem 'timecop'
gem 'rpush-redis', '0.1.0'

platform :mri do
  gem 'cane'
  gem 'codeclimate-test-reporter', require: nil
  gem 'simplecov', require: false
  gem 'rubocop', require: false
end

platform :ruby do
  gem 'pg'
  gem 'mysql2'
  gem 'yajl-ruby'
  gem 'sqlite3'
end

platform :jruby do
  gem 'activerecord-jdbc-adapter', '>= 1.2.6'
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'activerecord-jdbcmysql-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'activerecord-jdbch2-adapter'
  gem 'jdbc-postgres'
  gem 'jruby-openssl'
end

gemspec
