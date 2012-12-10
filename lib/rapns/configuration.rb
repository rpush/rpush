module Rapns
  def self.configuration
    @configuration ||= Rapns::Configuration.new
  end

  def self.configure
    yield configuration if block_given?
  end

  class Configuration < Struct.new(:foreground, :push_poll, :feedback_poll, :airbrake_notify, :check_for_errors, :pid_file, :batch_size)

    attr_accessor :apns_feedback_callback

    def initialize
      super

      self.foreground = false
      self.push_poll = 2
      self.feedback_poll = 60
      self.airbrake_notify = true
      self.check_for_errors = true
      self.batch_size = 5000
    end

    def on_apns_feedback(&block)
      self.apns_feedback_callback = block
    end
  end
end
