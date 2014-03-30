require 'redis'

require 'rpush/client/active_model'

require 'rpush/client/redis/app'
require 'rpush/client/redis/notification'

require 'rpush/client/redis/apns/app'

require 'rpush/client/redis/gcm/app'
require 'rpush/client/redis/gcm/notification'

require 'rpush/client/redis/adm/app'
require 'rpush/client/redis/adm/notification'

require 'rpush/client/redis/wpns/app'
require 'rpush/client/redis/wpns/notification'

module Rpush
  include Rpush::Client::Redis

  module Apns
    include Rpush::Client::Redis::Apns
  end

  module Gcm
    include Rpush::Client::Redis::Gcm
  end

  module Wpns
    include Rpush::Client::Redis::Wpns
  end

  module Adm
    include Rpush::Client::Redis::Adm
  end
end
