require 'fileutils'

def cmd(str, clean_env = true)
  puts "* #{str}"
  retval = clean_env ? Bundler.with_clean_env { `#{str}` } : `#{str}`
  puts retval.strip
  retval
end

task :build_rails do
  rpush_root = Dir.pwd
  path = '/tmp/rpush/rails_test'
  cmd("rm -rf #{path}")
  FileUtils.mkdir_p(path)
  pwd = Dir.pwd

  cmd("bundle exec rails --version", false)
  cmd("bundle exec rails new #{path} --skip-bundle", false)

  begin
    Dir.chdir(path)
    cmd('echo "gem \'rake\'" >> Gemfile')
    cmd('echo "gem \'pg\'" >> Gemfile')
    cmd("echo \"gem 'rpush', :path => '#{rpush_root}'\" >> Gemfile")
    cmd('bundle install')

    File.open('config/database.yml', 'w') do |fd|
      fd.write(<<-YML)
development:
  adapter: postgresql
  database: rpush_rails_test
  pool: 5
  timeout: 5000
      YML
    end
  ensure
    Dir.chdir(pwd)
  end

  puts "Built into #{path}"
end

task :build_standalone do
  rpush_root = Dir.pwd
  path = '/tmp/rpush/standalone_test'
  cmd("rm -rf #{path}")
  FileUtils.mkdir_p(path)
  pwd = Dir.pwd

  begin
    Dir.chdir(path)
    cmd('echo "source \'https://rubygems.org\'" >> Gemfile')
    cmd('echo "gem \'rake\'" >> Gemfile')
    cmd('echo "gem \'rpush-redis\'" >> Gemfile')
    cmd("echo \"gem 'rpush', :path => '#{rpush_root}'\" >> Gemfile")
    cmd('bundle install')
  ensure
    Dir.chdir(pwd)
  end

  puts "Built into #{path}"
end
