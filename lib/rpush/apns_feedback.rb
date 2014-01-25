module Rpush
  def self.apns_feedback
    Rpush.require_for_daemon
    Rpush::Daemon.initialize_store

    Rpush::Apns::App.all.each do |app|
      receiver = Rpush::Daemon::Apns::FeedbackReceiver.new(app, 0)
      receiver.check_for_feedback
    end

    nil
  end
end
