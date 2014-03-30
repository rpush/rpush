require 'active_record'

require 'rpush/client/active_model'

require 'rpush/client/active_record/notification'
require 'rpush/client/active_record/app'

require 'rpush/client/active_record/apns/notification'
require 'rpush/client/active_record/apns/feedback'
require 'rpush/client/active_record/apns/app'

require 'rpush/client/active_record/gcm/notification'
require 'rpush/client/active_record/gcm/app'

require 'rpush/client/active_record/wpns/notification'
require 'rpush/client/active_record/wpns/app'

require 'rpush/client/active_record/adm/notification'
require 'rpush/client/active_record/adm/app'

module Rpush
  include Rpush::Client::ActiveRecord

  module Apns
    include Rpush::Client::ActiveRecord::Apns
  end

  module Gcm
    include Rpush::Client::ActiveRecord::Gcm
  end

  module Wpns
    include Rpush::Client::ActiveRecord::Wpns
  end

  module Adm
    include Rpush::Client::ActiveRecord::Adm
  end
end
