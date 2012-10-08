namespace :test do
  task :build_rails do
    require 'fileutils'

    def cmd(str)
      puts "* #{str}"
      retval = Bundler.with_clean_env { `#{str}` }
      puts retval.strip
      retval
    end

    rapns_root = Dir.pwd
    path = '/tmp/rails_test'
    cmd("rm -rf #{path}")
    FileUtils.mkdir_p(path)
    pwd = Dir.pwd

    cmd("bundle exec rails new #{path} --skip-bundle")
    branch = cmd("git branch | grep '\*'").split(' ').last

    begin
      Dir.chdir(path)
      cmd('echo "gem \'rake\'" >> Gemfile')
      cmd("echo \"gem 'rapns', :git => '#{rapns_root}', :branch => '#{branch}'\" >> Gemfile")
      cmd('bundle install')
      cmd('bundle exec rails g rapns')
      cmd('bundle exec rake db:migrate')
    ensure
      Dir.chdir(pwd)
    end
  end
end