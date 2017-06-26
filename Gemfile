source 'https://rubygems.org'

# https://github.com/bundler/bundler/issues/5476
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'rake'
gem 'rspec', '~> 3.4.0'
gem 'database_cleaner'
gem 'timecop'
gem 'rpush-redis', '0.4.1'
gem 'rpush-mongoid', path: './rpush-mongoid'
gem 'net-http2'

platform :mri do
  gem 'cane'
  gem 'codeclimate-test-reporter', require: nil
  gem 'simplecov', require: false
  gem 'rubocop', require: false
  gem 'byebug'
end

platform :mri_21, :mri_22 do
  gem 'stackprof'
end

platform :ruby do
  gem 'pg'
  gem 'mysql2'
  gem 'sqlite3'
end

gemspec
