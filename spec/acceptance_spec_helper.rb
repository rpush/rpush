require 'unit_spec_helper'
require 'fileutils'

ENV['RAILS_ENV'] = 'test'
require 'bundler'
Bundler.require(:default)

TMP_DIR = '/tmp'
RAILS_DIR = File.join(TMP_DIR, 'rapns_test')
if ENV['TRAVIS']
  TRAVIS_BRANCH = 'master'
  RAPNS_ROOT = 'git://github.com/ileitch/rapns.git'
else
  RAPNS_ROOT = File.expand_path(__FILE__ + '/../../')
end

def setup_rails
  return if $rails_is_setup
  `rm -rf #{RAILS_DIR}`
  FileUtils.mkdir_p(RAILS_DIR)
  cmd("bundle exec rails --version", true, false)
  cmd("bundle exec rails new #{RAILS_DIR} --skip-bundle", true, false)
  branch = `git branch | grep '\*'`.split(' ').last
  in_test_rails do
    cmd('echo "gem \'rake\'" >> Gemfile')
    if ENV['TRAVIS']
      cmd("echo \"gem 'rapns', :git => '#{RAPNS_ROOT}', :branch => '#{TRAVIS_BRANCH}'\" >> Gemfile")
    else
      cmd("echo \"gem 'rapns', :git => '#{RAPNS_ROOT}', :branch => '#{branch}'\" >> Gemfile")
    end

    cmd("bundle install")
  end
end

def as_test_rails_db(env='development')
  orig_config = ActiveRecord::Base.connection_config
  begin
    in_test_rails do
      config = YAML.load_file('config/database.yml')
      ActiveRecord::Base.establish_connection(config[env])
      yield
    end
  ensure
    ActiveRecord::Base.establish_connection(orig_config)
  end
end

def cmd(str, echo = true, clean_env = true)
  puts "* #{str.strip}" if echo
  retval = if clean_env
    Bundler.with_clean_env { `#{str}` }
  else
    `#{str}`
  end
  puts retval.strip if echo && retval.strip != ""
  retval
end

def generate
  in_test_rails { cmd('bundle exec rails g rapns') }
end

def migrate(*migrations)
  in_test_rails do
    if migrations.present?
      migrations.each do |name|
        migration = Dir.entries('db/migrate').find { |entry| entry =~ /#{name}/ }
        version = migration.split('_').first
        cmd("bundle exec rake db:migrate VERSION=#{version} RAILS_ENV=development")
      end
    else
      cmd('bundle exec rake db:migrate RAILS_ENV=development')
    end
  end
end

def in_test_rails
  pwd = Dir.pwd
  begin
    Dir.chdir(RAILS_DIR)
    yield
  ensure
    Dir.chdir(pwd)
  end
end

def runner(str)
  in_test_rails { cmd("rails runner -e test '#{str}'").strip }
end
