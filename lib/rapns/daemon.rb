require "rapns/daemon/configuration"
require "rapns/daemon/certificate"

module Rapns
  module Daemon
    def self.start(environment, options)
      Configuration.load(environment, File.join(Rails.root, "config", "rapns", "rapns.yml"))
      Certificate.load(Configuration.certificate)
    end
  end
end