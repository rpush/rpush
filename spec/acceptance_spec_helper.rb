# require 'unit_spec_helper' # Shouldn't need to do this...
require 'fileutils'

ENV['RAILS_ENV'] = 'test'
require 'bundler'
Bundler.require(:default)

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
  branch = `git branch | grep '\*'`.split(' ').last
  in_test_rails do
    cmd('echo "gem \'rake\'" >> Gemfile')
    if ENV['TRAVIS']
      cmd("echo \"gem 'rapns', :git => '#{RAPNS_ROOT}'\" >> Gemfile")
    else
      cmd("echo \"gem 'rapns', :git => '#{RAPNS_ROOT}', :branch => '#{branch}'\" >> Gemfile")
    end

    cmd("bundle install")
  end
end

def cmd(str, echo = true)
  puts "* #{str}" if echo
  retval = Bundler.with_clean_env { `#{str}` }
  puts retval if echo
  retval
end

def generate
  in_test_rails { cmd('bundle exec rails g rapns') }
end

def migrate
  in_test_rails { cmd('bundle exec rake db:migrate') }
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

def read_fixture(fixture)
  path = File.join(File.dirname(__FILE__), 'acceptance/fixtures', fixture)
  if !File.exists?(path)
    STDERR.puts "MISSING FIXTURE: #{path}"
    pending
  else
    File.read(path)
  end
end

def start_rapns
  in_test_rails do
    Bundler.with_clean_env do
      IO.popen('bundle exec rapns test -f', 'r')
    end
  end
end