module Rpush
  def self.apns_feedback
    require 'rpush/daemon'
    Rpush::Daemon.common_init

    Rpush::Apns::App.all.each do |app|
      # Redis stores every App type on the same namespace, hence the
      # additional filtering
      next unless app.service_name == 'apns'

      receiver = Rpush::Daemon::Apns::FeedbackReceiver.new(app)
      receiver.check_for_feedback
    end

    nil
  end
end
