$LOAD_PATH.unshift('bm')
require 'bench'

n = 10

Rpush.configure do |config|
  config.client = :redis
  config.push_poll = 0.1
end

Bench.run do |x|
  x.report(:start_stop) do |x|
    n.times do
      Rpush.embed
      sleep 0.2
      Rpush.shutdown
    end
  end
end
