
# :nocov:
begin
  require 'mongoid'
  require 'autoinc'
rescue LoadError
  puts
  str = "* Please add 'rpush-mongoid' to your Gemfile to use the Mongoid client. *"
  puts "*" * str.size
  puts str
  puts "*" * str.size
  puts
end

require 'rpush/client/active_model'

require 'rpush/client/mongoid/notification'
require 'rpush/client/mongoid/app'

require 'rpush/client/mongoid/apns/notification'
require 'rpush/client/mongoid/apns/feedback'
require 'rpush/client/mongoid/apns/app'

require 'rpush/client/mongoid/apns2/notification'
require 'rpush/client/mongoid/apns2/app'

require 'rpush/client/mongoid/gcm/notification'
require 'rpush/client/mongoid/gcm/app'

require 'rpush/client/mongoid/wpns/notification'
require 'rpush/client/mongoid/wpns/app'

require 'rpush/client/mongoid/wns/notification'
require 'rpush/client/mongoid/wns/raw_notification'
require 'rpush/client/mongoid/wns/badge_notification'
require 'rpush/client/mongoid/wns/app'

require 'rpush/client/mongoid/adm/notification'
require 'rpush/client/mongoid/adm/app'
