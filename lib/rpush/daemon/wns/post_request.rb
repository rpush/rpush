module Rpush
  module Daemon
    module Wns
      class PostRequest
        def self.create(notification, access_token)
          is_raw_notification = lambda do |n|
            n.class.name.match(/RawNotification/)
          end

          stringify_keys = lambda do |data|
            data.keys.each { |key| data[key.to_s || key] = data.delete(key) }
          end

          stringify_keys.call(notification.data)

          if is_raw_notification.call(notification)
            RawRequest.create(notification, access_token)
          else
            ToastRequest.create(notification, access_token)
          end
        end
      end
    end
  end
end
