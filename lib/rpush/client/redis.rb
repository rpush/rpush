
# :nocov:
begin
  require 'modis'
  require 'redis'
rescue LoadError
  puts
  str = "* Please add 'rpush-redis' to your Gemfile to use the Redis client. *"
  puts "*" * str.size
  puts str
  puts "*" * str.size
  puts
end

require 'rpush/client/active_model'

require 'rpush/client/redis/app'
require 'rpush/client/redis/notification'

require 'rpush/client/redis/apns/app'
require 'rpush/client/redis/apns/notification'
require 'rpush/client/redis/apns/feedback'

require 'rpush/client/redis/apns2/app'
require 'rpush/client/redis/apns2/notification'

require 'rpush/client/redis/gcm/app'
require 'rpush/client/redis/gcm/notification'

require 'rpush/client/redis/adm/app'
require 'rpush/client/redis/adm/notification'

require 'rpush/client/redis/wpns/app'
require 'rpush/client/redis/wpns/notification'

require 'rpush/client/redis/wns/app'
require 'rpush/client/redis/wns/notification'
require 'rpush/client/redis/wns/raw_notification'
require 'rpush/client/redis/wns/badge_notification'

Modis.configure do |config|
  config.namespace = :rpush
end
