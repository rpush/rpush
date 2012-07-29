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
  branch = `git branch | grep '\*'`.split(' ').last
  in_test_rails do
    cmd('echo "gem \'rake\'" >> Gemfile')
    cmd("echo \"gem 'rapns', :git => '#{RAPNS_ROOT}', :branch => '#{branch}'\" >> Gemfile")
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
  in_test_rails { cmd('bundle exec rails g rapns') }
end

def migrate
  return if $migrated
  $migrated = true
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

class MissingFixtureError < StandardError; end

def read_fixture(fixture)
  path = File.join(File.dirname(__FILE__), 'acceptance/fixtures', fixture)
  if !File.exists?(path)
    raise MissingFixtureError, "MISSING FIXTURE: #{path}"
  else
    File.read(path)
  end
end

# def connect_console
#   in_test_rails do
#     Bundler.with_clean_env do
#       io = IO.popen('bundle exec rails c test', 'w+')
#       read_output(io) # Loading development environment (Rails x.x.x)
#       read_output(io) # Switch to inspect mode.
#       io.puts("ActiveRecord::Base.logger = ::Logger.new(nil)") # Turn of SQL logging.
#       io
#     end
#   end
# end

def start_rapns
  in_test_rails do
    Bundler.with_clean_env do
      IO.popen('bundle exec rapns test -f', 'r')
    end
  end
end

class Console
  def initialize
    in_test_rails do
      Bundler.with_clean_env do
        @io = IO.popen('bundle exec rails c test', 'w+')
      end
    end
    readline # Loading development environment (Rails x.x.x)
    readline # Switch to inspect mode.
    disable_logging
  end

  def exec(cmd)
    @io.puts(cmd)
    readline # ignore echo
    readline
  end

  def readline
    line = ''
    while result = IO.select([@io])
      next if result.empty?
      c = @io.read(1)
      break if c.nil? || c == "\n"
      line << c
    end
    p line
    line
  end

  def close
    @io.close
  end

  protected

  def disable_logging
    exec("ActiveRecord::Base.logger = ::Logger.new(nil)")
  end
end