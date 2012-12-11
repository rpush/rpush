module Rapns
  def self.config
    @config ||= Rapns::Configuration.new
  end

  def self.configure
    yield config if block_given?
  end

  ATTRS = [:foreground, :push_poll, :feedback_poll,
    :airbrake_notify, :check_for_errors, :pid_file, :batch_size]

  class Configuration < Struct.new(*ATTRS)
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

    def update(other)
      ATTRS.each { |attr| send("#{attr}=", other.send(attr)) }
    end

    def on_apns_feedback(&block)
      self.apns_feedback_callback = block
    end

    def pid_file=(path)
      if path && !Pathname.new(path).absolute?
        super(File.join(Rails.root, config.pid_file))
      else
        super
      end
    end
  end
end
