rails_env = 'production'
rails_root = '/var/www/my_site/current'
rails_shared = '/var/www/my_site/shared'

God.watch do |w|
  w.name = 'rapns'

  w.start = "cd #{rails_root} && bundle exec rapns #{rails_env}"
  w.stop = "kill -INT `cat #{rails_shared}/pids/rapns.pid`"

  w.uid = 'deploy'
  w.gid = 'deploy'

  w.pid_file = "#{rails_shared}/pids/rapns.pid"
  w.behavior(:clean_pid_file)

  w.keepalive
end