require 'redis'
require 'modis'

module Rpush
  module Client
    module Redis
      class App
        include Modis::Model
        self.namespace = 'apps'
      end

      class Notification
        include Modis::Model
        self.namespace = 'notifications'
      end
    end
  end
end

module Rpush
  module Daemon
    module Store
      class Redis
        include Rpush::Client::Redis
        include MultiJsonHelper

        def initialize
          Modis.configure do |config|
            config.key_namespace = :rpush
          end

          @redis = Redis.new
        end

        def all_apps
          App.all
        end

        def deliverable_notifications(apps)
          batch_size = app_batch_size(apps.size)
          notifications = @redis.pipelined do
            apps.each do |app|
              app.lrem(batch_size)
            end
          end

          build_notifications(notifications)
        end

        private

        def app_batch_size(num_apps)
          return 0 if num_apps == 0
          (Rpush.config.batch_size / num_apps).floor
        end

        def build_notifications(notifications)
          notifications.map do |notification|
            Notification.new(multi_json_load(notification))
          end
        end
      end
    end
  end
end
