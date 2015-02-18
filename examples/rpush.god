rails_env = 'production'
rails_root = '/var/www/my_site/current'
rails_shared = '/var/www/my_site/shared'

God.watch do |w|
  w.name = 'rpush'

  w.start = "cd #{rails_root} && bundle exec rpush start -f -e #{rails_env}"
  w.stop = "kill -INT `cat #{rails_shared}/pids/rpush.pid`"

  w.uid = 'deploy'
  w.gid = 'deploy'

  w.pid_file = "#{rails_shared}/pids/rpush.pid"
  w.behavior(:clean_pid_file)

  w.keepalive

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
    end

    # failsafe
    on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
    end
  end
end
