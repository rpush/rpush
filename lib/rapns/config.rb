module Rapns

  # A globally accessible instance of Rapns::Config
  def self.configuration
    @configuration ||= Rapns::Config.new
  end

  # Call the given block yielding to it the global Rapns::Config instance for setting
  # configuration values / callbacks.
  #
  # Typically this would be used in your Rails application's config/initializers/rapns.rb file
  def self.configure
    yield configuration if block_given?
  end

  # A class to hold Rapns configuration settings and callbacks.
  class Config < Struct.new(:foreground, :push_poll, :feedback_poll, :airbrake_notify, :check_for_errors, :pid_file, :batch_size)

    attr_accessor :feedback_callback

    # Initialize the Config with default values
    def initialize
      super

      # defaults:
      self.foreground = false
      self.push_poll = 2
      self.feedback_poll = 60
      self.airbrake_notify = true
      self.check_for_errors = true
      self.batch_size = 5000
    end

    # Define a block that will be executed with a Rapns::Feedback instance when feedback has been received from the
    # push notification servers that a notification has failed to be delivered. Further notifications should not
    # be sent to this device token.
    #
    # Example usage (in config/initializers/rapns.rb):
    #
    #  Rapns.configure do |config|
    #    config.on_feedback do |feedback|
    #      device = Device.find_by_device_token feedback.device_token
    #      if device
    #        device.active = false
    #        device.save
    #      end
    #    end
    #  end
    #
    # Where `Device` is a model specific to your Rails app that has a `device_token` field.
    def on_feedback(&block)
      self.feedback_callback = block
    end
  end
end