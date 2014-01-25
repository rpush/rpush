module Rpush
  module Daemon
    module Apns
      extend ServiceConfigMethods

      HOSTS = {
        :production  => ['gateway.push.apple.com', 2195],
        :development => ['gateway.sandbox.push.apple.com', 2195], # deprecated
        :sandbox     => ['gateway.sandbox.push.apple.com', 2195]
      }

      dispatcher :tcp, :host => Proc.new { |app| HOSTS[app.environment.to_s] }
      loops Rpush::Daemon::Apns::FeedbackReceiver
    end
  end
end
