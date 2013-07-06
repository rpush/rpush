namespace :test do
  task :build_rails do
    require 'fileutils'

    def cmd(str, clean_env = true)
      puts "* #{str}"
      retval = if clean_env
        Bundler.with_clean_env { `#{str}` }
      else
        `#{str}`
      end
      puts retval.strip
      retval
    end

    rapns_root = Dir.pwd
    path = '/tmp/rails_test'
    cmd("rm -rf #{path}")
    FileUtils.mkdir_p(path)
    pwd = Dir.pwd

    cmd("bundle exec rails --version", false)
    cmd("bundle exec rails new #{path} --skip-bundle", false)

    begin
      Dir.chdir(path)
      cmd('echo "gem \'rake\'" >> Gemfile')
      cmd("echo \"gem 'rapns', :path => '#{rapns_root}'\" >> Gemfile")
      cmd('bundle install')
      cmd('bundle exec rails g rapns')
      cmd('bundle exec rake db:migrate')
    ensure
      Dir.chdir(pwd)
    end

    puts "Built into #{path}"
  end
end
