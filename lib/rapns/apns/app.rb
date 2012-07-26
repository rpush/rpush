module Rapns
  module Apns
    class App < Rapns::App
      HOSTS = {
        :production => {
          :push => ['gateway.push.apple.com', 2195],
          :feedback => ['feedback.push.apple.com', 2196]
        },
        :development => {
          :push => ['gateway.sandbox.push.apple.com', 2195],
          :feedback => ['feedback.sandbox.push.apple.com', 2196]
        }
      }

      validates :environment, :presence => true, :inclusion => { :in => %w(development production) }
      validates :certificate, :presence => true

      def new_runner
        push_host, push_port = HOSTS[environment.to_sym][:push]
        feedback_host, feedback_port = HOSTS[environment.to_sym][:feedback]
        feedback_poll = Rapns::Daemon.config.feedback_poll
        Rapns::Daemon::Apns::AppRunner.new(self, push_host, push_port, feedback_host, feedback_port, feedback_poll)
      end
    end
  end
end