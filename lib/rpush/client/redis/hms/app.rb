module Rpush
  module Client
    module Redis
      module Hms
        # required auth_key
        # required name
        # required hms_app_id
        class App < Rpush::Client::Redis::App
          include Rpush::Client::ActiveModel::Hms::App
        end
      end
    end
  end
end
