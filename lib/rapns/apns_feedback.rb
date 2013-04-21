module Rapns
  def self.apns_feedback
    Rapns.require_for_daemon
    Rapns::Daemon.initialize_store

    Rapns::Apns::App.all.each do |app|
      receiver = Rapns::Daemon::Apns::FeedbackReceiver.new(app, 0)
      receiver.check_for_feedback
    end

    nil
  end
end
