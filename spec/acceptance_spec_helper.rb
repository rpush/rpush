require 'unit_spec_helper' # Shouldn't need to do this...
require 'fileutils'

TMP_DIR = '/tmp'
RAILS_DIR = File.join(TMP_DIR, 'rapns_test')
RAPNS_ROOT = File.expand_path(__FILE__ + '/../../')

def setup_rapns
  setup_rails
  generate
  migrate
end

def setup_rails
  return if $rails_is_setup
  `rm -rf #{RAILS_DIR}`
  FileUtils.mkdir_p(RAILS_DIR)
  cmd("bundle exec rails new #{RAILS_DIR} --skip-bundle")
  in_directory(RAILS_DIR) do
    cmd('echo "gem \'rake\'" >> Gemfile')
    cmd("echo \"gem 'rapns', :git => '#{RAPNS_ROOT}'\" >> Gemfile")
    Bundler.with_clean_env { cmd("bundle") }
  end
end

def cmd(str)
  puts "* #{str}"
  Bundler.with_clean_env { `#{str}` }
  $? == 0
end

def generate
  return if $generated
  $generated = true
  in_directory(RAILS_DIR) { cmd('bundle exec rails g rapns') }
end

def migrate
  return if $migrated
  $migrated = true
  in_directory(RAILS_DIR) { cmd('bundle exec rake db:migrate') }
end

def in_directory(dir)
  pwd = Dir.pwd
  begin
    puts "* cd #{dir}"
    Dir.chdir(dir)
    yield
  ensure
    puts "* cd #{pwd}"
    Dir.chdir(pwd)
  end
end